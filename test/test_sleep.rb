# frozen_string_literal: true
require 'bundler/setup'
require 'minitest/autorun'
require 'libev_scheduler'

class TestFiberSleep < MiniTest::Test
  ITEMS = [0, 1, 2, 3, 4]

  def setup
    sleep 0.1
  end

  def test_sleep
    items = []

    thread = Thread.new do
      scheduler = Libev::Scheduler.new
      Fiber.set_scheduler scheduler

      5.times do |i|
        Fiber.schedule do
          assert_operator sleep(i/100.0), :>=, 0
          items << i
        end
      end
    end

    thread.join

    assert_equal ITEMS, items
  end

  def test_sleep_returns_seconds_slept
    seconds = nil
    t0 = Time.now

    thread = Thread.new do
      scheduler = Libev::Scheduler.new
      Fiber.set_scheduler scheduler
      Fiber.schedule do
        seconds = sleep(1)
      end
    end

    thread.join
    elapsed = Time.now - t0

    assert_operator seconds, :>=, 1.0, "actual: %p" % seconds
    assert_operator elapsed, :>=, 1.0, "actual: %p" % elapsed
  end

  def test_raise_exits_sleep
    finished = false
    thread = Thread.new do
      scheduler = Libev::Scheduler.new
      Fiber.set_scheduler scheduler
      f = Fiber.schedule do
        sleep
      rescue
        finished = true
      end
      Fiber.schedule {f.raise}
    end

    thread.join
    assert finished
  end
end
