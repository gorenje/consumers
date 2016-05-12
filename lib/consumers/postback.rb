module Consumers
  class Postback
    include Sidekiq::Worker

    sidekiq_options :queue => :batch_postback

    attr_reader :redis_queue

    def initialize
      @redis_queue = RedisQueue.new($redis_pool, :url_queue)
    end

    def perform
      $kafka_postback_consumer.subscribe("inapp")
      $kafka_postback_consumer.each_message do |message|

      end
    rescue Exception => e
      puts e.message
      puts e.backtrace
    end

    private


    def invalid_queue
      @invalid_queue ||= RedisQueue.new($redis_pool, :url_invalid)
    end
  end
end
