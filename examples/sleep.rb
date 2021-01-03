require 'bundler/setup'
require 'libev_scheduler'

Fiber.set_scheduler Libev::Scheduler.new
Fiber.schedule do
  puts "going to sleep"
  t0 = Time.now
  sleep 1.5
  puts "woke up after #{Time.now - t0} seconds"
end
