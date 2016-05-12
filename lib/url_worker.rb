class UrlWorker
  include Sidekiq::Worker

  sidekiq_options :queue => :batch

  attr_reader :redis_queue

  def initialize
    @redis_queue = RedisQueue.new($redis_pool, :url_queue)
  end

  def perform(batch_size)
    urls = redis_queue.pop(batch_size).map do |str|
      next if str.nil?

    end.compact

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
