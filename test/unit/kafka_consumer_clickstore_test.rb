# encoding: UTF-8
require_relative '../test_helper'

class KafkaConsumerClickstoreTest < Minitest::Test

  def setup
    @clickstore = RedisExpiringSet.new($redis.click_store)
    @clickstore.clear!

    @clickstats = RedisClickStats.new($redis.click_stats)
    @clickstats.clear!

    @consumer = Consumers::Clickstore.new
  end

  context "perform" do
    should "call start_kafka_stream" do
      mock(@consumer).
        start_kafka_stream(:click, "clicks", "clicks", 60)
      @consumer.perform
    end
  end

  context "do_work" do
    should "not handle non-click events" do
      msg = "/t/notclick m p"

      mock(@consumer).handle_exception.times(0)

      _,stdout,stderr = silence_is_golden do
        @consumer.send(:do_work, make_kafka_message(msg))
      end

      assert_match /MESSAGE OFFSET/, stdout
      assert_not_match /EVENT DELAY/, stdout

      assert_equal [], @clickstore.keys.sort
    end

    should "store clicks without adid" do
      msg = EventPayloads.click

      _,stdout,stderr = silence_is_golden do
        @consumer.send(:do_work, make_kafka_message(msg))
      end

      assert_match /MESSAGE OFFSET/, stdout
      assert_match /EVENT DELAY/, stdout

      assert @clickstore.keys.include?("1c0cdbd7358cf020ecbb9fd8d19972cf")
      assert @clickstats.keys.include?("clickstats:cl:46")

      assert_equal([["count", 1.0], ["country:DE", 1.0], ["device:", 1.0],
                    ["device_type:desktop", 1.0], ["platform:mac", 1.0]],
                   @clickstats.
                   zrange("clickstats:cl:46",0,-1, :withscores => true))

      assert_equal(msg, @clickstore.
                   zrange("1c0cdbd7358cf020ecbb9fd8d19972cf",0,-1,
                          :withscores => true).first.first)
    end
  end
end
