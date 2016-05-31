require_relative 'base'

module Consumers
  class Attribution
    include Consumers::Base
    include Sidekiq::Worker

    sidekiq_options :queue => :attribution_consumer

    SevenDays = 7 * 24 * 60 * 60

    def initialize
      @redis_clickstore       = RedisExpiringSet.new($redis.click_store)
      @listen_to_these_events = ["ist"]
    end

    def perform
      $kafka.attribution.consumer(:group_id => "attribution").tap do |c|
        c.subscribe("inapp")
      end.each_message(:loop_count => 60) do |message|
        do_work(message)
      end
    rescue
      handle_exception($!)
      nil
    end

    protected

    def do_work(message)
      puts "MESSAGE OFFSET (attribution): #{message.offset} / (#{message.partition})"
      event = Consumers::Kafka::InstallEvent.new(message.value)
      return unless @listen_to_these_events.include?(event.call)
      puts "EVENT DELAY (attribution) #{event.delay_in_seconds} seconds"

      results = @redis_clickstore.
        find_by_lookup_keys(event.lookup_keys, event.time - 300,
                            event.time + SevenDays)

      unless results.empty?
        puts "FOUND MATCH"
        key,values = results.first
        click_payload = values.first
        @redis_clickstore.remove_value_from_key(key, click_payload)

        click = Consumers::Kafka::ClickEvent.new(click_payload)
        Postback.find_postback_for_conversion(click, "mac").
          each do |postback|
          NetworkUser.create_new_for_conversion(click,event,postback)
        end

        AdtekioTracking::Events.new.
          conversion({:click => click.payload, :install => event.payload})
      end
    end
  end
end
