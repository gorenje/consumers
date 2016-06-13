# encoding: UTF-8
require_relative '../test_helper'

class KafkaConsumerConversionTest < Minitest::Test

  def setup
    @redis_queue = RedisQueue.new($redis.local, :url_queue)
    @redis_queue.clear!
    Postback.delete_all
    @consumer = Consumers::Conversion.new
  end

  context "perform" do
    should "call start_kafka_stream" do
      mock(@consumer).
        start_kafka_stream(:conversion, "conversion", "inapp", 15)
      @consumer.perform
    end
  end

  context "do_work" do
    should "not handle apo events" do
      msg = "/t/apo m p"
      mock(@consumer).handle_exception.times(0)

      any_instance_of(Consumers::Kafka::ConversionEvent) do |o|
        mock(o).generate_urls.times(0)
      end

      mock($librato_queue).add("conversion_delay" => 1).times(0)
      mock($librato_aggregator).add("conversion_url_count" => 1).times(0)

      @consumer.send(:do_work, make_kafka_message(msg))

      assert_equal 0, @redis_queue.size
    end

    should "not handle mac without install" do
      msg = EventPayloads.conversion.gsub(/[&]install=%2F.+$/,'')

      mock(@consumer).handle_exception.times(0)

      mock($librato_queue).add("conversion_delay" => 10)
      mock($librato_aggregator).add("conversion_url_count" => 1).times(0)

      any_instance_of(Consumers::Kafka::ConversionEvent) do |o|
        mock(o).generate_urls.times(0)
        mock(o).delay_in_seconds { 10 }
      end

      @consumer.send(:do_work, make_kafka_message(msg))

      assert_equal 0, @redis_queue.size
    end

    should "not handle mac without click" do
      msg = EventPayloads.conversion.gsub(/ click=.+[&]install/,' install')

      mock(@consumer).handle_exception.times(0)

      mock($librato_queue).add("conversion_delay" => 10)
      mock($librato_aggregator).add("conversion_url_count" => 1).times(0)

      any_instance_of(Consumers::Kafka::ConversionEvent) do |o|
        mock(o).generate_urls.times(0)
        mock(o).delay_in_seconds { 10 }
      end

      @consumer.send(:do_work, make_kafka_message(msg))

      assert_equal 0, @redis_queue.size
    end

    should "with a valid mac, do work" do
      msg = EventPayloads.conversion

      mock(@consumer).handle_exception.times(0)

      mock($librato_queue).add("conversion_delay" => 10)
      mock($librato_aggregator).add("conversion_url_count" => 3)

      any_instance_of(Consumers::Kafka::ConversionEvent) do |o|
        mock(o).generate_urls({ }) { [1,2,3] }
        mock(o).delay_in_seconds { 10 }
      end

      clickstats = RedisExpiringSet.new($redis.click_store)
      clickstats.clear!

      @consumer.send(:do_work, make_kafka_message(msg))

      assert_equal 3, @redis_queue.size

      assert_equal(41, Consumers::Kafka::ConversionEvent.new(msg).
                   click.campaign_link_id.to_i)

      assert_equal([["conversion", 1.0], ["conversion:country:US", 1.0]],
                   clickstats.
                   zrange("clickstats:cl:41",0,-1, :withscores => true))
    end
  end
end
