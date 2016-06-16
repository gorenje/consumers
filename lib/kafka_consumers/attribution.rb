require_relative 'base'

module Consumers
  class Attribution
    include Consumers::Base
    include Sidekiq::Worker

    sidekiq_options :queue => :attribution_consumer

    SevenDays = 7 * 24 * 60 * 60

    def initialize
      @url_queue        = RedisQueue.new($redis.local, :tracking_url_queue)
      @redis_clickstore = RedisExpiringSet.new($redis.click_store)
      handle_these_events(["ist"])
      initialize_cache do
        Postback.cache_for_attribution_consumer
      end
    end

    def perform
      start_kafka_stream(:attribution, "attribution", "inapp", 600)
    rescue
      handle_exception($!)
      nil
    end

    protected

    def do_work(message)
      Consumers::Kafka::InstallEvent.new(message.value).tap do |event|
        handle_event(event)
      end
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

        update_cache(300) do
          $librato_queue.add("attribution_cache_update" => 1)
          Postback.cache_for_attribution_consumer
        end

        # click = Consumers::Kafka::ClickEvent.new(click_payload)
        # cache[click.network][click.user_id.to_i].each do |postback|
        #   NetworkUser.create_new_for_conversion(click,event,postback)
        # end

        # @url_queue.
        #   jpush([Tracking::Event.new.
        #          conversion({ :click   => click.payload,
        #                       :install => event.payload})])
      end
    end
  end
end
