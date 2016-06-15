# encoding: UTF-8
require_relative '../test_helper'

class KafkaConsumerClickstatsTest < Minitest::Test

  def setup
    @clickstats = RedisClickStats.new($redis.click_stats)
    @clickstats.clear!

    @consumer = Consumers::Clickstats.new
  end

  context "perform" do
    should "call start_kafka_stream" do
      mock(@consumer).
        start_kafka_stream(:clickstats, "clickstats", "clicks", 400)
      @consumer.perform
    end
  end

  context "do_work" do
    should "not handle non-click events" do
      msg = "/t/notclick m p"

      mock(@consumer).handle_exception.times(0)

      @consumer.send(:do_work, make_kafka_message(msg))

      assert_equal [], @clickstats.keys.sort
    end

    should "store clicks without adid" do
      msg = EventPayloads.click

      @consumer.send(:do_work, make_kafka_message(msg))
      @consumer.send(:done_handling_messages)

      assert @clickstats.keys.include?("clickstats:cl:46")

      assert_equal([["count", 1.0], ["country:DE", 1.0], ["device:", 1.0],
                    ["device_type:desktop", 1.0], ["platform:mac", 1.0]],
                   @clickstats.
                   zrange("clickstats:cl:46",0,-1, :withscores => true))
    end
  end
end
