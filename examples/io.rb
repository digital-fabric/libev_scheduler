require 'bundler/setup'
require 'libev_scheduler'
require 'fiber'

scheduler = Libev::Scheduler.new
Fiber.set_scheduler scheduler

i, o = IO.pipe

Fiber.schedule do
  sleep 0.4
  o.write 'Hello, world!'
  o.close
end

Fiber.schedule do
  puts "hi"
  5.times do
    sleep 0.1
    puts "."
  end
end

# Fiber.schedule do
#   scheduler.block(:wait)
# end

Fiber.schedule do
  message = i.read
  puts message
end
