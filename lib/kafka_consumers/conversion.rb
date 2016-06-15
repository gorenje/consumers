require_relative 'base'

module Consumers
  class Conversion
    include Consumers::Base
    include Sidekiq::Worker

    sidekiq_options :queue => :conversion_consumer

    def initialize
      @redis_queue            = RedisQueue.new($redis.local, :url_queue)
      @redis_stats            = RedisClickStats.new($redis.click_stats)
      @listen_to_these_events = ["mac"]

      initialize_cache(:cache_for_conversion_event)
    end

    def perform
      start_kafka_stream(:conversion, "conversion", "inapp", 60)
    rescue
      handle_exception($!)
      nil
    end

    protected

    def do_work(message)
      event = Consumers::Kafka::ConversionEvent.new(message.value)
      return(event) unless @listen_to_these_events.include?(event.call)
      handle_event(event)
      event
    end

    def handle_event(event)
      return if event.params[:click].nil? or event.params[:install].nil?

      update_cache(300) do
        $librato_queue.add("conversion_cache_update" => 1)
        @postback_cache = Postback.cache_for_conversion_event
      end

      urls = event.generate_urls(@postback_cache)
      $librato_aggregator.add("conversion_url_count" => urls.size)
      @redis_queue.jpush(urls)

      @redis_stats.conversion(event.click, event.install)
    end
  end
end
