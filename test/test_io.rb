# frozen_string_literal: true
require 'bundler/setup'
require 'minitest/autorun'
require 'libev_scheduler'

class TestFiberIO < MiniTest::Test
  MESSAGE = "Hello World"

  def test_read
    i, o = IO.pipe

    message = nil

    thread = Thread.new do
      scheduler = Libev::Scheduler.new
      Fiber.set_scheduler scheduler

      Fiber.schedule do
        message = i.read(20)
        i.close
      end

      Fiber.schedule do
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

  def test_raise
    i, o = IO.pipe
    finished = false

    thread = Thread.new do
      scheduler = Libev::Scheduler.new
      Fiber.set_scheduler scheduler

      f = Fiber.schedule do
        i.read
      rescue
        finished = true
      end

      Fiber.schedule do
        f.raise
      end
    end

    thread.join
    assert finished
  end
end
