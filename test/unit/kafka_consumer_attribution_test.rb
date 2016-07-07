# encoding: UTF-8
require_relative '../test_helper'

class KafkaConsumerAttributionTest < Minitest::Test

  def setup
    @url_queue = RedisQueue.new($redis.local, :tracking_url_queue)
    @url_queue.clear!

    Postback.delete_all
    @consumer = Consumers::Attribution.new

    @clickstore = RedisExpiringSet.new($redis.click_store)
    @clickstore.clear!

    NetworkUser.delete_all
  end

  context "perform" do
    should "should call start_kafka_stream" do
      mock(@consumer).
        start_kafka_stream_by_message(:attribution, "attribution", "inapp", 600)

      @consumer.perform
    end
  end

  context "do_work" do
    should "ignore non-install events" do
      msg = "/t/notist m p"

      mock(@consumer).handle_exception.times(0)
      assert_equal ["ist"], @consumer.instance_variable_get("@listen_to_these_events")

      @consumer.send(:do_work, make_kafka_message(msg))
    end

    should "lookup click events but do nothing if nothing found" do
      msg = EventPayloads.install

      any_instance_of(RedisExpiringSet) do |o|
        mock(o).
          find_by_lookup_keys(["bb0ca0283abd536a7ae2941c6cde29dd",
                               "95d2e39592433fd4bf10a72f5573f8dc",
                               "35ce2f8bf63cfda46551a68097e2badc",
                               "35382295a43b6abe8337fa2da486baa7"],
                              DateTime.parse("2016-05-31 16:31:57 +0000"),
                              DateTime.parse("2016-06-07 16:36:57 +0000")) {[]}
      end

      @consumer.send(:do_work, make_kafka_message(msg))

      assert_zero @url_queue.size
    end

    should "lookup click event and trigger mac call if match found" do
      msg = EventPayloads.install

      any_instance_of(RedisExpiringSet) do |o|
        mock(o).
          find_by_lookup_keys(["bb0ca0283abd536a7ae2941c6cde29dd",
                               "95d2e39592433fd4bf10a72f5573f8dc",
                               "35ce2f8bf63cfda46551a68097e2badc",
                               "35382295a43b6abe8337fa2da486baa7"],
                              DateTime.parse("2016-05-31 16:31:57 +0000"),
                              DateTime.parse("2016-06-07 16:36:57 +0000")) do
          [["95d2e39592433fd4bf10a72f5573f8dc", [EventPayloads.click]]]
        end
        mock(o).remove_value_from_key("95d2e39592433fd4bf10a72f5573f8dc",
                                      EventPayloads.click)
      end

      click = Consumers::Kafka::ClickEvent.new(EventPayloads.click)

      assert_equal({}, @consumer.cache)
      @consumer.send(:do_work, make_kafka_message(msg))

      mac_url = Tracking::Event.new.
        conversion({ :click   => EventPayloads.click,
                     :install => EventPayloads.install})

      assert_one @url_queue.size
      assert_equal(JSON.parse(mac_url.to_json), @url_queue.jpop.first)
      assert_zero NetworkUser.count
    end

    should "lookup click event, trigger mac call, and store user" do
      msg = EventPayloads.install

      ptbmk = generate_postback(:user_id => "1", :network => "7games",
                        :store_user => true, :event => "mac")
      @consumer = Consumers::Attribution.new # regenerate cache
      assert_equal({"7games"=>{1=>[ptbmk]}}, @consumer.cache)

      any_instance_of(RedisExpiringSet) do |o|
        mock(o).
          find_by_lookup_keys(["bb0ca0283abd536a7ae2941c6cde29dd",
                               "95d2e39592433fd4bf10a72f5573f8dc",
                               "35ce2f8bf63cfda46551a68097e2badc",
                               "35382295a43b6abe8337fa2da486baa7"],
                              DateTime.parse("2016-05-31 16:31:57 +0000"),
                              DateTime.parse("2016-06-07 16:36:57 +0000")) do
          [["95d2e39592433fd4bf10a72f5573f8dc", [EventPayloads.click]]]
        end
        mock(o).remove_value_from_key("95d2e39592433fd4bf10a72f5573f8dc",
                                      EventPayloads.click)
      end

      click = Consumers::Kafka::ClickEvent.new(EventPayloads.click)

      mock(NetworkUser).create_new_for_conversion(anything,anything,ptbmk)

      @consumer.send(:do_work, make_kafka_message(msg))

      mac_url = Tracking::Event.new.
        conversion({ :click   => EventPayloads.click,
                     :install => EventPayloads.install})

      assert_one @url_queue.size
      assert_equal(JSON.parse(mac_url.to_json), @url_queue.jpop.first)
    end
  end
end
