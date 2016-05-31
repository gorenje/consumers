require_relative 'base'

module Consumers
  class Conversion
    include Consumers::Base
    include Sidekiq::Worker

    sidekiq_options :queue => :conversion_consumer

    def initialize
      @redis_queue            = RedisQueue.new($redis_pool, :url_queue)
      @redis_stats            = RedisClickStats.new($redis_click_pool)
      @listen_to_these_events = ["mac"]
    end

    def perform
      $kafka.conversion.consumer(:group_id => "conversion").tap do |c|
        c.subscribe("inapp")
      end.each_message(:loop_count => 15) do |message|
        do_work(message)
      end
    rescue
      handle_exception($!)
      nil
    end

    protected

    def do_work(message)
      puts "MESSAGE OFFSET (conversion): #{message.offset}"
      event = Consumers::Kafka::ConversionEvent.new(message.value)
      return unless @listen_to_these_events.include?(event.call)
      return if event.params[:click].nil? or event.params[:install].nil?

      urls = event.generate_urls
      puts "DUMPING #{urls.size} URLS TO REDIS"
      @redis_queue.jpush(urls)

      @redis_stats.conversion(event.click, event.install)
    end
  end
end
