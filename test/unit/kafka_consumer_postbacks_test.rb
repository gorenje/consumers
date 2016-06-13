# encoding: UTF-8
require_relative '../test_helper'

class KafkaConsumerPostbacksTest < Minitest::Test

  def setup
    @redis_queue = RedisQueue.new($redis.local, :url_queue)
    @redis_queue.clear!
    Postback.delete_all
    @consumer = Consumers::Postbacks.new
  end

  context "perform" do
    should "call start_kafka_stream" do
      mock(@consumer).
        start_kafka_stream(:postback, "postback", "inapp", 15)
      @consumer.perform
    end
  end

  context "do_work" do
    should "not handle mac events" do
      msg = "/t/mac m p"

      mock(@consumer).handle_exception.times(0)

      _,stdout,stderr = silence_is_golden do
        @consumer.send(:do_work, make_kafka_message(msg))
      end

      assert_match /MESSAGE OFFSET/, stdout
      assert_not_match /EVENT DELAY/, stdout

      assert_equal 0, @redis_queue.size
    end

    should "not handle apo events if there are postbacks" do
      assert_equal [], Postback.unique_events
      msg = "/t/apo m p"

      mock(@consumer).handle_exception.times(0)

      _,stdout,stderr = silence_is_golden do
        @consumer.send(:do_work, make_kafka_message(msg))
      end

      assert_match /MESSAGE OFFSET/, stdout
      assert_not_match /EVENT DELAY/, stdout

      assert_equal 0, @redis_queue.size
    end

    should "handle apo if there are postbacks" do
      generate_postback(:url_template => "http://google.de", :event => "apo")
      assert_equal ["apo"], Postback.unique_events
      @consumer = Consumers::Postbacks.new # update listen_to_these_events

      msg = "/t/apo m p"

      mock(@consumer).handle_exception.times(0)

      _,stdout,stderr = silence_is_golden do
        @consumer.send(:do_work, make_kafka_message(msg))
      end

      assert_match /MESSAGE OFFSET/, stdout
      assert_match /EVENT DELAY/, stdout
      assert_equal 1, @redis_queue.size
      assert_equal({"url"=>"http://google.de", "body"=>nil, "header"=>{}},
                   JSON.parse(@redis_queue.pop.first))
    end
  end
end
