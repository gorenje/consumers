module Consumers
  class TrackingUrlWorker
    include Sidekiq::Worker

    sidekiq_options :queue => :tracking_url_worker

    attr_reader :redis_queue

    def initialize
      @redis_queue = RedisQueue.new($redis.local, :tracking_url_queue)
    end

    def perform(batch_size)
      redis_queue.jpop(batch_size).map do |hsh|
        Consumers::Request::UrlHandler.new(hsh).fire_url
      end
    rescue Exception => e
      puts e.message
      puts e.backtrace
    end
  end
end
