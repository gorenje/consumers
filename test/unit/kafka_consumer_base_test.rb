# encoding: UTF-8
require_relative '../test_helper'

class KafkaConsumerBaseTest < Minitest::Test

  class TestConsumer
    include Consumers::Base
  end

  context "update cache for postback" do
    should "have initialisation" do
      consumer = TestConsumer.new

      mock(Postback).cache_for_conversion_event { "fubar" }
      consumer.initialize_cache(:cache_for_conversion_event)

      assert_equal "fubar", consumer.instance_variable_get("@postback_cache")
    end

    should "do update if necessary" do
      consumer = TestConsumer.new

      consumer.instance_variable_set("@cache_timestamp", Time.now - 20)

      consumer.update_cache(10) do
        consumer.instance_variable_set("@postback_cache", "banana")
      end

      assert_equal "banana", consumer.instance_variable_get("@postback_cache")
    end
  end

  context "start a kafka stream" do
    should "call do_work" do
      consumer = TestConsumer.new

      kafka_message = make_kafka_message("fubar")
      batch         = OpenStruct.new(:messages => [kafka_message])
      consumer_name = "name"
      group_id      = "group"
      topic         = "topic"
      loop_count    = "loop_count"
      event         = OpenStruct.new(:delay_in_seconds => 30)

      ko = Object.new.tap do |o|
        mock(o).consumer(:group_id => group_id) { o }
        mock(o).subscribe(topic)
        mock(o).each_batch(:loop_count => loop_count).yields(batch)
      end

      orig_dollar_kafka = $kafka
      $kafka = { consumer_name => ko }

      mock($librato_queue).add("name_offset" => 1)
      mock($librato_queue).add("name_event_delay" => 30)
      mock(consumer).do_work(kafka_message) {event}
      consumer.start_kafka_stream(consumer_name, group_id, topic, loop_count)

      $kafka = orig_dollar_kafka
    end

  end
end
