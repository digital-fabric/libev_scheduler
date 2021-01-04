# libev_scheduler

<p align="center">
  <a href="http://rubygems.org/gems/libev_scheduler">
    <img src="https://badge.fury.io/rb/libev_scheduler.svg" alt="Ruby gem">
  </a>
  <a href="https://github.com/digital-fabric/libev_scheduler/actions?query=workflow%3ATests">
    <img src="https://github.com/digital-fabric/libev_scheduler/workflows/Tests/badge.svg" alt="Tests">
  </a>
  <a href="https://github.com/digital-fabric/libev_scheduler/blob/master/LICENSE">
    <img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="MIT License">
  </a>
</p>

`libev_scheduler` is a libev-based fiber scheduler for Ruby 3.0 based on code
extracted from [Polyphony](https://github.com/digital-fabric/libev_scheduler).

## Installing

```bash
$ gem install libev_scheduler
```

## Usage

```ruby
Fiber.set_scheduler Libev::Scheduler.new

Fiber.schedule do
  do_something_awesome
end
```

Also have a look at the included tests and examples.

## Some notes on the implementation

The present gem uses
[libev](http://pod.tst.eu/http://cvs.schmorp.de/libev/ev.pod) to provide a
performant, cross-platform fiber scheduler implementation for Ruby 3.0. While I
intend to update the bundled libev code to the latest version, which includes an
io_uring backend, it is unclear to me that this has real benefits (see below for
more information).

## Some thoughts on the Ruby fiber scheduler interface

The fiber scheduler interface is a new feature in Ruby 3.0, aimed at
facilitating building fiber-based concurrent applications in Ruby. The current
[specification](https://docs.ruby-lang.org/en/master/Fiber/SchedulerInterface.html)
includes methods for:

- starting a non-blocking fiber
- waiting for an `IO` instance to become ready for reading or writing
- sleeping for a certain time duration
- waiting for a process to terminate
- otherwise pausing/resuming fibers (blocking/unblocking) for use with mutexes,
  condition variables, queues etc.

However, the current design has some shortcomings that will need to be addressed
in order for this feature to become useful. Here are some of my thoughts on this
subject. Please do not take this as an attack on the wonderful work of the Ruby
core developers. At worst I'm just some guy being wrong on the internet :-p.

## I/O readiness

In and of itself, checking for I/O readiness is nice, but it does not allow us
to leverage the power of e.g. io_uring or IOCP in Windows. In order to leverage
the advantages offered by io_uring, for instance, a fiber scheduler should be
able to do much more than check for I/O readiness. It should be able, rather, to
perform I/O operations including read/write, send/recv, connect and accept.

This is of course no small undertaking, but the current Ruby [native I/O
code](https://github.com/ruby/ruby/blob/master/io.c), currently at almost 14
KLOCS, is IMHO ripe for some overhauling, and maybe some separation of concerns.
It seems to me that at the API layer (e.g. the `IO` and `Socket` classes) could
be separated from the code that does the actual reading/writing etc. This is
indeed the approach I took with
[Polyphony](https://github.com/digital-fabric/polyphony/), which provides the
same API for developers, but performs the I/O using a libev- or io_uring-based
backend. This design can then reap all of the benefits of using io_uring. Such
an approach could also allow allow us to implement I/O using IOCP on Windows
(currently we can't because this requires files to be opened with
`WSA_FLAG_OVERLAPPED`).

This is also the reason I have decided to not release a native io_uring-backed
fiber scheduler implementation, since I don't think it can provide a real
benefit in terms of performance. If I/O readiness is all that the fiber
scheduler can do, it's best to just use a cross-platform implementation such as
libev, which can then use io_uring behind the scenes.

## Waiting for processes

The problem with the current design is that the `#process_wait` method is
expected to return an instance of `Process::Status`. Unfortunately, this class
[cannot be
instantiated](https://github.com/ruby/ruby/blob/master/process.c#L8678), which
leads to a workaround using a separate thread.

Another difficulty associated with this is that for example on libev, a child
watcher can only be used on the default loop, which means only in the main
thread, as the child watcher implementation is based on receiving `SIGCHLD`.

An alternative solution would be to use `pidfd_open` and watch the returned fd,
but I don't know if this can be used on OSes other than linux. 

While a cross-OS solution to the latter problem is probably not too difficult,
the former problem is a real show-stopper. One solution might be to change the
API such that `#process_wait` returns an array containing the pid and its
status, for example. This can then be used to instantiate a `Process::Status`
object somewhere inside `Process.wait`.

## Performing blocking operations on the main fiber

While I didn't scratch the surface too much in terms of the limits of the fiber
scheduler feature, it looks pretty clear that the main fiber (in any thread)
cannot be used in a non-blocking manner. While fiber scheduler implementations
can in principle use `Fiber#transfer` to switch between fibers, which will allow
pausing and resuming the main fiber, it does not seem as if the current design
is really conductive to that.

## The idea of multiple fiber scheduler implementations

It is unclear to me that there is really a need for multiple fiber scheduler
implementations. First of all, the term "fiber scheduler" is a bit of a
misnomer, since it doesn't really deal with *scheduling* fibers, but really with
*performing blocking operations in a fiber-aware manner*. The scheduling part is
in many ways trivial, but the performing of blocking operations is [much more
involved](https://github.com/digital-fabric/polyphony/blob/master/ext/polyphony/backend_io_uring.c).

There is of course quite a bit of interaction between the scheduling part and
the blocking operations part, but again, to me a more sensible design would have
been to do everything related to scheduling inside of the Ruby core code, and
then offload everything else to a `BlockingOperationsBackend` implementation.
Here's what it might look like (with the current capabilities):

```ruby
class BlockingOperationsBackend
  def io_wait(io, opts)
  end

  def pid_wait(pid, opts)
  end

  def sleep(duration)
  end

  def poll(opts = {})
  end
end
```

The fiber scheduling part would provide a `Thread#schedule_fiber` method that
adds the given fiber to the thread's run queue, and the thread will know when to
call the backend's `#poll` method in order to poll for blocking operation
completions.

It seems to me this kind of design would be much easier to implement, and would
lead to a lot less code duplication.
