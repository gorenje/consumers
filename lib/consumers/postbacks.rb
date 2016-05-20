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
      kafka_postback_consumer =
        $kafka_postback.consumer(:group_id => "postback")

      kafka_postback_consumer.subscribe("inapp")
      kafka_postback_consumer.each_message(:loop_count => 15) do |message|
        puts "MESSAGE OFFSET: #{message.offset}"
        event = Consumers::Kafka::PostbackEvent.new(message.value)
        next unless @listen_to_these_events.include?(event.call)
        urls = event.generate_urls
        puts "DUMPING #{urls.size} URLS TO REDIS"
        @redis_queue.jpush(urls)
      end
    rescue
      puts "Preventing retries on error"
      nil
    end
  end
end
