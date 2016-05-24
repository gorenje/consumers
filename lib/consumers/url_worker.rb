module Consumers
  class UrlWorker
    include Sidekiq::Worker

    sidekiq_options :queue => :url_worker

    attr_reader :redis_queue

    def initialize
      @redis_queue = RedisQueue.new($redis_pool, :url_queue)
    end

    def perform(batch_size)
      redis_queue.jpop(batch_size).map do |hsh|
        status,resp_code = Consumers::Request::UrlHandler.new(hsh).fire_url
        AdtekioTracking::Events.new.
          postback({:req => hsh.to_json, :s => status, :rc => resp_code})
      end
    rescue Exception => e
      puts e.message
      puts e.backtrace
    end

    private

    def store_invalid_clicks(clicks)
      invalid_queue.push(clicks)
    end

    def requeue_failed_clicks(clicks)
      redis_queue.push(clicks)
    end

    def invalid_queue
      @invalid_queue ||= RedisQueue.new($redis_pool, :url_invalid)
    end
  end
end