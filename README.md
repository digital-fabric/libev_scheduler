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
extracted from [Polyphony](https://github.com/digital-fabric/polyphony).

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

## The scheduler implementation

The present gem uses
[libev](http://pod.tst.eu/http://cvs.schmorp.de/libev/ev.pod) to provide a
performant, cross-platform fiber scheduler implementation for Ruby 3.0. The
bundled libev is version 4.33, which includes an (experimental) io_uring
backend.

## The Ruby fiber scheduler interface

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

Here are some of my [thoughts](thoughts.md) on this interface.
