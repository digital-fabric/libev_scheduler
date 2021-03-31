# frozen_string_literal: true
require 'bundler/setup'
require 'minitest/autorun'
require 'minitest/reporters'
require 'libev_scheduler'
require 'io/wait'

class TestFiberIO < MiniTest::Test
  MESSAGE = "Hello World"

  def test_read
    i, o = IO.pipe

    message = nil

    thread = Thread.new do
      scheduler = Libev::Scheduler.new
      Fiber.set_scheduler scheduler

      Fiber.schedule do
        assert i.wait_readable
        message = i.read(20)
        i.close
      end

      Fiber.schedule do
        assert o.wait_writable
        o.write("Hello World")
        o.close
      end
    end

    thread.join

    assert_equal MESSAGE, message
    assert_predicate(i, :closed?)
    assert_predicate(o, :closed?)
  end

  def test_heavy_read
    16.times.map do
      Thread.new do
        i, o = IO.pipe

        scheduler = Libev::Scheduler.new
        Fiber.set_scheduler scheduler

        Fiber.schedule do
          i.read(20)
          i.close
        end

        Fiber.schedule do
          o.write("Hello World")
          o.close
        end
      end
    end.each(&:join)
  end

  def test_timeout
    i, o = IO.pipe

    thread = Thread.new do
      scheduler = Libev::Scheduler.new
      Fiber.set_scheduler scheduler

      Fiber.schedule do
        assert_nil i.wait_readable(0.1)
        assert_raises IO::WaitReadable do
          i.read_nonblock(1)
        end
      end
    end

    thread.join
  end
end
