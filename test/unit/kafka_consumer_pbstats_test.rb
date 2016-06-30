# encoding: UTF-8
require_relative '../test_helper'

class KafkaConsumerPbstatsTest < Minitest::Test

  def setup
    @clickstats = RedisClickStats.new($redis.click_stats)
    @clickstats.clear!

    @consumer = Consumers::Pbstats.new
  end

  context "perform" do
    should "call start_kafka_stream" do
      mock(@consumer).
        start_kafka_stream(:pbstats, "pbstats", "inapp", 600)
      @consumer.perform
    end
  end

  context "do_work" do
    should "not handle non-pob events" do
      msg = "/t/notpob m p"

      mock(@consumer).handle_exception.times(0)

      @consumer.send(:do_work, make_kafka_message(msg))

      assert_equal [], @clickstats.keys.sort
    end

    should "not handle pob events where pbid is missing" do
      msg = "/t/pob m rc=200"

      mock(@consumer).handle_exception.times(0)

      @consumer.send(:do_work, make_kafka_message(msg))

      assert_equal [], @clickstats.keys.sort
    end

    should "not handle pob events where response code is missing" do
      msg = "/t/pob m pbid=200"

      mock(@consumer).handle_exception.times(0)

      @consumer.send(:do_work, make_kafka_message(msg))

      assert_equal [], @clickstats.keys.sort
    end

    should "store pods with everything" do
      msg = EventPayloads.postback

      @consumer.send(:do_work, make_kafka_message(msg))
      @consumer.send(:done_handling_messages)

      assert @clickstats.keys.include?("pbstats:pb:312")

      assert_equal([["count", 1.0], ["respcode:200", 1.0]],
                   @clickstats.
                   zrange("pbstats:pb:312",0,-1, :withscores => true))
    end
  end
end
