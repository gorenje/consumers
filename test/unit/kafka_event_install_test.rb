# encoding: UTF-8
require_relative '../test_helper'

class KafkaEventInstallTest < Minitest::Test

  def setup
    @payload = EventPayloads.install
    @event = Consumers::Kafka::InstallEvent.new(@payload)
    NetworkUser.delete_all
    Postback.delete_all
  end

  context "basics" do
    should "have lookup keys - based on idfa" do
      assert_equal ["bb0ca0283abd536a7ae2941c6cde29dd",
                    "95d2e39592433fd4bf10a72f5573f8dc",
                    "35ce2f8bf63cfda46551a68097e2badc",
                    "35382295a43b6abe8337fa2da486baa7"], @event.lookup_keys
    end

    should "have lookup keys - based on ip & platform" do
      @payload = "/t/ist bot_name&country=DE&device=smartphone&device_name="+
        "iPhone&ip=3160894398&klag=1&platform=ios&ts=1464712617 "+
        "device=fubar"
      @event = Consumers::Kafka::InstallEvent.new(@payload)

      assert_equal ["35382295a43b6abe8337fa2da486baa7"], @event.lookup_keys
    end
  end
end
