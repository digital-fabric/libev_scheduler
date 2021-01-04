require_relative './libev_scheduler_ext'

module Libev
  class Scheduler
    def fiber(&block)
      fiber = Fiber.new(blocking: false, &block)
      unblock(nil, fiber)
      # fiber.resume
      return fiber
    end

    def kernel_sleep(duration = nil)
      block(:sleep, duration)
    end

    def process_wait(pid, flags)
      # This is a very simple way to implement a non-blocking wait:
      Thread.new do
        Process::Status.wait(pid, flags)
      end.value
    end  
  end
end