require 'bundler/setup'
require 'libev_scheduler'

Fiber.set_scheduler Libev::Scheduler.new
Fiber.schedule do
  puts "going to sleep"
  sleep 1
  puts "woke up"
end
