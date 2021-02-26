require 'bundler/setup'
require 'libev_scheduler'

require 'socket'

scheduler = Libev::Scheduler.new
Fiber.set_scheduler scheduler

server = TCPServer.new('localhost', 9090)

Fiber.schedule do
  loop do
    p pre: server
    client = server.accept
    p client: client

    Fiber.schedule do
      client.recv(1024)
      client.send("HTTP/1.1 200 Ok\r\nConnection: close\r\n\r\n",0)
      client.close
    end
  end
end
