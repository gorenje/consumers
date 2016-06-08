# encoding: UTF-8
require_relative '../test_helper'

class KafkaEventTest < Minitest::Test

  def setup
    @payload =
      "/t/click bot_name&country=DE&device=desktop&device_name&ip="+
      "2986893172&klag=1&platform=mac&ts=1465409418 "+
      "ad=&adgroup=&adid&attr_window_from=2016-06-08T18%3A10%3A18%2B00%3A00&"+
      "attr_window_till=2016-06-09T03%3A46%3A18%2B00%3A00&campaign=fubar&"+
      "campaign_link_id=45&click=&created_at="+
      "2016-06-08T18%3A10%3A18%2B00%3A00&idfa_comb&lookup_key="+
      "bd6f07d51abcafbeaf86a7d3b5628ad7&network=zemail&partner_data&"+
      "redirect_url=https%3A%2F%2Fplay.google.com%2Fstore%2Fapps%2Fdetails%3Fid%3Dsu&reqparams=&user_id=1"
  end

  context "basics" do
    should "do lazy initialisation of params & meta" do
      event = Consumers::Kafka::ClickEvent.new(@payload)

      assert_nil event.instance_variable_get("@params")
      assert_nil event.instance_variable_get("@meta")

      assert !event.instance_variable_get("@_meta").blank?
      assert !event.instance_variable_get("@_params").blank?

      # this a meta piece of information
      assert_equal "DE", event.country

      assert event.instance_variable_get("@meta")
      assert_nil event.instance_variable_get("@params")

      # this a params piece of information
      assert_equal "zemail", event.network

      assert event.instance_variable_get("@params")
    end

    should "have a bunch of attributes" do
      event = Consumers::Kafka::ClickEvent.new(@payload)

      assert_equal "zemail",       event.network
      assert_equal "DE",           event.country
      assert_equal "2986893172",   event.ip
      assert_equal "178.8.95.116", event.ip_dot_notation
      assert_equal "mac",          event.platform
      assert_equal "1465409418",   event.ts
      assert_equal "desktop",      event.device

      assert_equal "2016-06-08 18:10:18 +0000", event.time.to_s

      assert_nil event.device_name
      assert_nil event.bot_name
    end
  end
end
