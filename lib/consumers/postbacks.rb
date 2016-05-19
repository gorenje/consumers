module Consumers
  class Postbacks
    include Sidekiq::Worker

    sidekiq_options :queue => :batch_postback

    attr_reader :redis_queue

    def initialize
      @redis_queue            = RedisQueue.new($redis_pool, :url_queue)
      @listen_to_these_events = Postback.unique_events
    end

    def perform
      $kafka_postback_consumer.subscribe("inapp")
      $kafka_postback_consumer.each_message do |message|
        event = Consumers::Kafka::PostbackEvent.new(message.value)
        next unless @listen_to_these_events.include?(event.call)
        @redis_queue.jpush(event.generate_urls)
      end
    rescue Exception => e
      puts e.message
      puts e.backtrace
    end
  end
end
