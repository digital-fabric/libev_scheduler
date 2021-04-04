# Some thoughts on the Ruby fiber scheduler interface

The current design of the fiber scheduler interface has some shortcomings that
will need to be addressed in order for this feature to become useful.

Please do not take this as an attack on the wonderful work of the Ruby
core developers. Most probably I'm just some random guy being wrong on the
internet :-p.

## Two kinds of fibers

One of the changes made as part of the work on the fiber scheduler interface in
Ruby 3.0 was to distinguish between two kinds of fibers: a normal, blocking
fiber; and a non-blocking fiber, which can be used in conjunction with the fiber
scheduler. While this was probably done for the sake of backward compatibility,
I believe this is an error. It introduces ambiguity where previously there was
none and makes the API more complex that it could have been.

It seems to me that a more logical solution to the problem of maintaining the
blocking behaviour by default, would be have been to set the non-blocking mode
at the level of the thread, instead of the fiber. That also would have allowed
using the main fiber (of a given thread) in a non-blocking manner (see below).

## Performing blocking operations on the main fiber

While I didn't scratch the surface too much in terms of the limits of the fiber
scheduler interface, it looks pretty clear that the main fiber (in any thread)
cannot be used in a non-blocking manner. While fiber scheduler implementations
can in principle use `Fiber#transfer` to switch between fibers, which will allow
pausing and resuming the main fiber, it does not seem as if the current design
is really conductive to that. Again, as discussed above, this can lead to
confusion.

## Waiting for processes

The problem with the current design is that the `#process_wait` method is
expected to return an instance of `Process::Status`. Unfortunately, this class
[cannot be
instantiated](https://github.com/ruby/ruby/blob/master/process.c#L8678), which
leads to a workaround using a separate thread.

Another difficulty associated with this is that for example on libev, a child
watcher can only be used on the default loop, which means only in the main
thread, as the child watcher implementation is based on receiving `SIGCHLD`.

An alternative solution would be to use `pidfd_open` and watch the returned fd
for readiness, but I don't know if this can be used on OSes other than linux. 

While a cross-OS solution to the latter problem is potentially not too
difficult, the former problem is a real show-stopper. One solution might be to
change the API such that `#process_wait` returns an array containing the pid and
its status, for example. This can then be used to instantiate a
`Process::Status` object somewhere inside `Process.wait`.

## On having multiple alternative fiber scheduler implementations

It is unclear to me that there is really a need for multiple fiber scheduler
implementations. It seems to me that an approach using multiple backends
selected according to the OS, is much more appropriate. It's not like there's
going to be a dozen different implementations of fiber schedulers. Actually,
libev fits really nicely here, since it already includes all those different
backends.


Besides, the term "fiber scheduler" is a bit of a misnomer, since it doesn't
really deal with *scheduling* fibers, but really with *performing blocking
operations in a fiber-aware manner*. The scheduling part is in many ways trivial
(i.e. the scheduler holds an array of fibers ready to run), but the performing
of blocking operations is [much more
involved](https://github.com/digital-fabric/polyphony/blob/master/ext/polyphony/backend_io_uring.c).

There is of course quite a bit of interaction between the scheduling part and
the blocking operations part, but then again to me a more sensible design would
have been to do everything related to scheduling inside of the Ruby core code,
and then offload everything else to a `BlockingOperationsBackend`
implementation. Here's what it might look like:

```ruby
# example pseudo-code
class BlockingOperationsBackend
  def poll(opts = {})
    ev_run(@ev_loop)    
  end

  def io_wait(io, opts)
    fiber = Fiber.current
    watcher = setup_watcher_for_io(io) do
      Thread.current.schedule_fiber(fiber)
    end
    Fiber.yield
    watcher.stop
  end

  ...
end
```

The fiber scheduling part would provide a `Thread#schedule_fiber` method that
adds the given fiber to the thread's run queue, and the thread will know when to
call the backend's `#poll` method in order to poll for blocking operation
completions. For example:

```ruby
# somewhere in Ruby's kischkas:
class Thread
  def schedule_fiber(fiber)
    @run_queue << fiber
  end

  def run_fiber_scheduler
    @backend.poll
    @run_queue.each { |f| f.resume }
  end
end
```

It seems to me this kind of design would be much easier to implement, and would
lead to a lot less code duplication. This design could also be extended later to
perform all kinds of blocking operations, such as reading/writing etc., as
discussed above.

Finally, such a design could also provide a C API for people writing extensions,
so they can rely on it whenever doing any blocking call.
