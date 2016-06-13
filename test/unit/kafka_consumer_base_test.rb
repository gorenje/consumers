# encoding: UTF-8
require_relative '../test_helper'

class KafkaConsumerBaseTest < Minitest::Test

  class TestConsumer
    include Consumers::Base
  end

  context "start a kafka stream" do
    should "call do_work" do
      consumer = TestConsumer.new

      kafka_message = make_kafka_message("fubar")
      consumer_name = "name"
      group_id      = "group"
      topic         = "topic"
      loop_count    = "loop_count"

      ko = Object.new.tap do |o|
        mock(o).consumer(:group_id => group_id) { o }
        mock(o).subscribe(topic)
        mock(o).each_message(:loop_count => loop_count).yields(kafka_message)
      end

      orig_dollar_kafka = $kafka
      $kafka = { consumer_name => ko }

      mock(consumer).do_work(kafka_message) {}
      consumer.start_kafka_stream(consumer_name, group_id, topic, loop_count)

      $kafka = orig_dollar_kafka
    end

  end
end
