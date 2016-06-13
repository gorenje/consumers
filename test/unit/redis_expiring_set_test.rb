# encoding: UTF-8
require_relative '../test_helper'

class RedisExpiringSetTest < Minitest::Test

  def setup
    @clickstore = RedisExpiringSet.new($redis.click_store)
    @clickstore.clear!
  end

  context "storage" do
    should "be able to store events" do
      event = Consumers::Kafka::ClickEvent.new(EventPayloads.click)
      mock(event).max_age { Time.now + 200 }

      # WARNING: works only with redis 2.8.x, 2.6.x will return -1
      assert_equal -2, @clickstore.ttl(event.lookup_key)

      @clickstore.add_click_event(event)
      assert @clickstore.ttl(event.lookup_key) > 150
      assert_equal 1, @clickstore.zcard(event.lookup_key)
    end

    should "update ttl when adding a new entry" do
      event = Consumers::Kafka::ClickEvent.new(EventPayloads.click)
      mock(event).max_age { Time.now + 200 }

      @clickstore.add_click_event(event)
      assert @clickstore.ttl(event.lookup_key) > 150
      assert_equal 1, @clickstore.zcard(event.lookup_key)

      event = Consumers::Kafka::ClickEvent.new(EventPayloads.click)
      mock(event).max_age { Time.now + 1200 }

      @clickstore.add_click_event(event)
      assert @clickstore.ttl(event.lookup_key) > 1000
      # payload is the same, so there isn't a new entry in the set
      # only the ttl gets updated.
      assert_equal 1, @clickstore.zcard(event.lookup_key)
    end
  end

  context "expire from set" do
    should "remove old members" do
      t   = Time.now
      key = "fubar"

      events = [{ :payload => "payload1",
                  :max_age => t + 2,
                },
                { :payload => "payload2",
                  :max_age => t + 3,
                },
                { :payload => "payload3",
                  :max_age => t + 4,
                }].map { |a| OpenStruct.new(a.merge(:lookup_key => key)) }

      events.each { |e| @clickstore.add_click_event(e) }
      assert_equal 3, @clickstore.zcard(key)

      @clickstore.expire!(key, t + 2)
      assert_equal 2, @clickstore.zcard(key)
      @clickstore.expire!(key, t + 2)
      assert_equal 2, @clickstore.zcard(key)
      @clickstore.expire!(key, t + 3)
      assert_equal 1, @clickstore.zcard(key)
      @clickstore.expire!(key, t + 3)
      assert_equal 1, @clickstore.zcard(key)
      @clickstore.expire!(key, t + 4)
      assert_equal 0, @clickstore.zcard(key)
    end
  end
end
