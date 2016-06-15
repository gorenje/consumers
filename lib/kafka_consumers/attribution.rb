require_relative 'base'

module Consumers
  class Attribution
    include Consumers::Base
    include Sidekiq::Worker

    sidekiq_options :queue => :attribution_consumer

    SevenDays = 7 * 24 * 60 * 60

    def initialize
      @url_queue = RedisQueue.new($redis.local, :tracking_url_queue)

      @redis_clickstore       = RedisExpiringSet.new($redis.click_store)
      @listen_to_these_events = ["ist"]
    end

    def perform
      start_kafka_stream(:attribution, "attribution", "inapp", 60)
    rescue
      handle_exception($!)
      nil
    end

    protected

    def do_work(message)
      event = Consumers::Kafka::InstallEvent.new(message.value)
      return(event) unless @listen_to_these_events.include?(event.call)
      handle_event(event)
      event
    end

    def handle_event(event)
      results = @redis_clickstore.
        find_by_lookup_keys(event.lookup_keys, event.time - 300,
                            event.time + SevenDays)

      unless results.empty?
        $librato_aggregator.add("attribution_found_match" => 1)

        key,values = results.first
        click_payload = values.first
        @redis_clickstore.remove_value_from_key(key, click_payload)

        click = Consumers::Kafka::ClickEvent.new(click_payload)
        Postback.where_we_need_to_store_user(click).
          each do |postback|
          NetworkUser.create_new_for_conversion(click,event,postback)
        end

        @url_queue.
          jpush([Tracking::Event.new.
                 conversion({ :click   => click.payload,
                              :install => event.payload})])
      end
    end
  end
end
