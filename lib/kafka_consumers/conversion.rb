require_relative 'base'

module Consumers
  class Conversion
    include Consumers::Base
    include Sidekiq::Worker

    sidekiq_options :queue => :conversion_consumer

    def initialize
      @redis_queue = RedisQueue.new($redis.local, :url_queue)
      @redis_stats = RedisClickStats.new($redis.click_stats)

      handle_these_events(["mac"])
      initialize_cache do
        Postback.cache_for_conversion_event
      end
    end

    def perform
      start_kafka_stream(:conversion, "conversion", "inapp", 600)
    rescue
      handle_exception($!)
      nil
    end

    protected

    def do_work(message)
      Consumers::Kafka::ConversionEvent.new(message.value).tap do |event|
        handle_event(event)
      end
    end

    def handle_event(event)
      return if event.params[:click].nil? or event.params[:install].nil?

      update_cache(300) do
        $librato_queue.add("conversion_cache_update" => 1)
        Postback.cache_for_conversion_event
      end

      urls = event.generate_urls(cache)
      $librato_aggregator.add("conversion_url_count" => urls.size)

      @redis_queue.jpush(urls)
      @redis_stats.conversion(event.click, event.install)
    end

    def done_handling_messages
      @redis_stats.flush
    end
  end
end
