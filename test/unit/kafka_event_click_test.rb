# encoding: UTF-8
require_relative '../test_helper'

class KafkaEventClickTest < Minitest::Test

  def setup
    @payload = EventPayloads.click
    @event = Consumers::Kafka::ClickEvent.new(@payload)
  end

  context "basics" do
    should "have access to the original payload" do
      assert_equal @payload, @event.payload
    end

    should "do lazy initialisation of params & meta" do
      assert_nil @event.instance_variable_get("@params")
      assert_nil @event.instance_variable_get("@meta")

      assert !@event.instance_variable_get("@_meta").blank?
      assert !@event.instance_variable_get("@_params").blank?

      # this a meta piece of information
      assert_equal "DE", @event.country

      assert @event.instance_variable_get("@meta")
      assert_nil @event.instance_variable_get("@params")

      # this a params piece of information
      assert_equal "7games", @event.network

      assert @event.instance_variable_get("@params")
    end

    should "have a bunch of attributes" do
      assert_equal "7games",       @event.network
      assert_equal "DE",           @event.country
      assert_equal "2986884497",   @event.ip
      assert_equal "178.8.61.145", @event.ip_dot_notation
      assert_equal "mac",          @event.platform
      assert_equal "1465468519",   @event.ts
      assert_equal "desktop",      @event.device
      assert_equal "1",            @event.klag

      assert_equal "2016-06-09 10:35:19 +0000", @event.time.to_s

      assert_nil @event.device_name
      assert_nil @event.bot_name
    end

    should "have a correct lookup key" do
      want = Digest::MD5.
        hexdigest("#{@event.ip_dot_notation}.#{@event.platform}".downcase)
      assert_equal want, @event.lookup_key
    end

    should "have a correct attribution window, bot, idfa and max_age" do
      from = @event.attribution_window.first
      till = @event.attribution_window.last
      assert from < till

      assert !@event.has_adid?
      assert !@event.is_bot?
      assert_equal till, @event.max_age
    end

    should "have click_data for storage" do
      assert_equal( {"partner_data" => "fubar",
                      "click"       => "click",
                      "ad"          => "",
                      "adgroup"     => "",
                      "campaign"    => "fubsada",
                      "andmore"     => ["data"],
                      "someother"   => ["data"]},
                    @event.click_data_for_network_user)
    end

    should "have working reqparams" do
      ["/t/click ts=1465468519 reqparams=&user_id=1",
       "/t/click ts=1465468519 reqparams&user_id=1",
       "/t/click ts=1465468519 user_id=1"
      ].each do |payload|
        assert_equal({},
                     Consumers::Kafka::ClickEvent.new(payload).request_params,
                     "Failed for #{payload}")
      end
    end
  end
end
