# encoding: UTF-8
require_relative '../test_helper'

class KafkaConsumerClickstoreTest < Minitest::Test

  def setup
    @clickstore = RedisExpiringSet.new($redis.click_store)
    @clickstore.clear!
    @consumer = Consumers::Clickstore.new
  end

  context "storage" do
    should "not handle non-click events" do
      msg = "/t/notclick m p"
      mock($kafka).click { kafka_mock("clicks", "clicks", 60, msg) }

      mock(@consumer).handle_exception.times(0)

      _,stdout,stderr = silence_is_golden do
        @consumer.perform
      end

      assert_match /MESSAGE OFFSET/, stdout
      assert_not_match /EVENT DELAY/, stdout

      assert_equal [], @clickstore.keys.sort
    end

    should "store clicks without adid" do
      msg = "/t/click bot_name&country=DE&device=desktop&device_name&"+
        "ip=2986884497&klag=1&platform=mac&ts=1465468519 ad=&adgroup=&adid&"+
        "attr_window_from=2016-06-09T10%3A35%3A19%2B00%3A00&"+
        "attr_window_till=2016-06-10T10%3A35%3A19%2B00%3A00&campaign=fubsada&"+
        "campaign_link_id=46&click=click&created_at=2016-06-09T10%3A35%3A19"+
        "%2B00%3A00&idfa_comb&lookup_key=1c0cdbd7358cf020ecbb9fd8d19972cf&"+
        "network=7games&partner_data=fubar&redirect_url=https%3A%2F%2F"+
        "play.google.com%2Fstore%2Fapps%2Fdetails%3Fid%3Dadsad&"+
        "reqparams=andmore%3Ddata%26someother%3Ddata&user_id=1"
      mock($kafka).click { kafka_mock("clicks", "clicks", 60, msg) }

      _,stdout,stderr = silence_is_golden do
        @consumer.perform
      end

      assert_match /MESSAGE OFFSET/, stdout
      assert_match /EVENT DELAY/, stdout
      assert_equal ["1c0cdbd7358cf020ecbb9fd8d19972cf",
                    "clickstats:cl:46"], @clickstore.keys.sort

      assert_equal([["count", 1.0], ["country:DE", 1.0], ["device:", 1.0],
                    ["device_type:desktop", 1.0], ["platform:mac", 1.0]],
                   @clickstore.
                   zrange("clickstats:cl:46",0,-1, :withscores => true))

      assert_equal(msg, @clickstore.
                   zrange("1c0cdbd7358cf020ecbb9fd8d19972cf",0,-1,
                          :withscores => true).first.first)
    end
  end
end
