require_relative './libev_scheduler_ext'

module Libev
  class Scheduler
    def fiber(&block)
      fiber = Fiber.new(blocking: false, &block)
      fiber.resume
      return fiber
    end

    def kernel_sleep(duration = nil)
      block(:sleep, duration)
    end

    def run
      puts "run"
    end
  end
end