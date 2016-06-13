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
    end

    def perform
      start_kafka_stream(:conversion, "conversion", "inapp", 15)
    rescue
      handle_exception($!)
      nil
    end

    protected

    def do_work(message)
      puts "MESSAGE OFFSET (conversion): #{message.offset}"
      event = Consumers::Kafka::ConversionEvent.new(message.value)
      return unless @listen_to_these_events.include?(event.call)
      puts "EVENT DELAY (conversion) #{event.delay_in_seconds} seconds"

      return if event.params[:click].nil? or event.params[:install].nil?

      urls = event.generate_urls
      puts "DUMPING #{urls.size} URLS TO REDIS (conversion)"
      @redis_queue.jpush(urls)

      @redis_stats.conversion(event.click, event.install)
    end
  end
end
