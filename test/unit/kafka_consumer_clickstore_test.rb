# encoding: UTF-8
require_relative '../test_helper'

class KafkaConsumerClickstoreTest < Minitest::Test

  def setup
    @clickstore = RedisExpiringSet.new($redis.click_store)
    @clickstore.clear!

    @consumer = Consumers::Clickstore.new
  end

  context "perform" do
    should "call start_kafka_stream" do
      mock(@consumer).
        start_kafka_stream(:clickstore, "clicks", "clicks", 600)
      @consumer.perform
    end
  end

  context "do_work" do
    should "store clicks without adid" do
      msg = EventPayloads.click

      @consumer.send(:do_work, make_kafka_message(msg))
      @consumer.send(:done_handling_messages)

      assert @clickstore.keys.include?("1c0cdbd7358cf020ecbb9fd8d19972cf")

      assert_equal(msg, @clickstore.
                   zrange("1c0cdbd7358cf020ecbb9fd8d19972cf",0,-1,
                          :withscores => true).first.first)
    end
  end
end
