require 'bundler/setup'
require 'libev_scheduler'

Fiber.set_scheduler Libev::Scheduler.new

# GC.disable

Fiber.schedule do
  finish = false
  Fiber.schedule do
    # sleep 0 until finish
    while !finish
      # p 1.0
      sleep 0
      # p 1.1
    end
  # rescue TypeError => e
  #   q << "1 *********************"
  #   q << e.inspect
  end
  # q << '3'
  sleep 0.1
  # q << '4'
  finish = true
# rescue TypeError => e
#   q << "2 *********************"
#   q << e.inspect
end
