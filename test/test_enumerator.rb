# frozen_string_literal: true
require 'bundler/setup'
require 'minitest/autorun'
require 'minitest/reporters'
require 'libev_scheduler'

class TestFiberEnumerator < MiniTest::Test
  MESSAGE = "Hello World"

  def test_read_characters
    i, o = IO.pipe

    message = String.new

    thread = Thread.new do
      scheduler = Libev::Scheduler.new
      Fiber.set_scheduler scheduler

      e = i.to_enum(:each_char)

      Fiber.schedule do
        o.write("Hello World")
        o.close
      end

      Fiber.schedule do
        begin
          while c = e.next
            message << c
          end
        rescue StopIteration
          # Ignore.
        end

        i.close
      end
    end

    thread.join

    assert_equal(MESSAGE, message)
    assert_predicate(i, :closed?)
    assert_predicate(o, :closed?)
  end
end
