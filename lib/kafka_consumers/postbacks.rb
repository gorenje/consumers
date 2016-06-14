require_relative 'base'

module Consumers
  class Postbacks
    include Consumers::Base
    include Sidekiq::Worker

    sidekiq_options :queue => :postback_consumer

    attr_reader :redis_queue

    def initialize
      @redis_queue            = RedisQueue.new($redis.local, :url_queue)
      @listen_to_these_events = Postback.unique_events - ["mac"]

      initialize_cache(:cache_for_postback_event)
    end

    def perform
      start_kafka_stream(:postback, "postback", "inapp", 15)
    rescue
      handle_exception($!)
      nil
    end

    protected

    def do_work(message)
      event = Consumers::Kafka::PostbackEvent.new(message.value)
      return unless @listen_to_these_events.include?(event.call)
      $librato_queue.add("postback_delay" => event.delay_in_seconds)

      update_cache(300) do
        $librato_queue.add("postback_cache_update" => 1)
        @postback_cache = Postback.cache_for_postback_event
      end

      urls = event.generate_urls(@postback_cache)
      $librato_aggregator.add("postback_url_count" => urls.size)
      @redis_queue.jpush(urls)
    end
  end
end
