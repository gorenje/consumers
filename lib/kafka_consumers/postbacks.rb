require_relative 'base'

module Consumers
  class Postbacks
    include Consumers::Base
    include Sidekiq::Worker

    sidekiq_options :queue => :postback_consumer

    attr_reader :redis_queue

    def initialize
      @redis_queue = RedisQueue.new($redis.local, :url_queue)

      handle_these_events(Postback.unique_events - ["mac"])
      initialize_cache do
        Postback.cache_for_postback_event
      end
    end

    def perform
      start_kafka_stream(:postback, "postback", "inapp", 600)
    rescue
      handle_exception($!)
      nil
    end

    protected

    def do_work(message)
      Consumers::Kafka::PostbackEvent.new(message.value).tap do |event|
        handle_event(event)
      end
    end

    def handle_event(event)
      update_cache(300) do
        $librato_queue.add("postback_cache_update" => 1)
        Postback.cache_for_postback_event
      end

      urls = event.generate_urls(cache)
      $librato_aggregator.add("postback_url_count" => urls.size)
      @redis_queue.jpush(urls)
    end
  end
end
