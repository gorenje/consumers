module Consumers
  class Postbacks
    include Sidekiq::Worker

    sidekiq_options :queue => :postback_consumer

    attr_reader :redis_queue

    def initialize
      @redis_queue            = RedisQueue.new($redis_pool, :url_queue)
      @listen_to_these_events = Postback.unique_events
    end

    def perform
      tstamp = Time.now

      $kafka_postback_consumer.subscribe("inapp")
      $kafka_postback_consumer.each_message do |message|
        event = Consumers::Kafka::PostbackEvent.new(message.value)
        next unless @listen_to_these_events.include?(event.call)
        @redis_queue.jpush(event.generate_urls)
        $kafka_postback_consumer.stop if (Time.now - tstamp) > 55
      end

    rescue Exception => e
      puts e.message
      puts e.backtrace
    end
  end
end
