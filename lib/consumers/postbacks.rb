module Consumers
  class Postbacks
    include Sidekiq::Worker

    sidekiq_options :queue => :postback_consumer

    attr_reader :redis_queue

    def initialize
      @redis_queue            = RedisQueue.new($redis_pool, :url_queue)
      @listen_to_these_events = Postback.unique_events - ["mac"]
    end

    def perform
      $kafka.postback.consumer(:group_id => "postback").tap do |c|
        c.subscribe("inapp")
      end.each_message(:loop_count => 15) do |message|
        do_work(message)
      end
    rescue
      puts "Preventing retries on error: #{$!}"
      puts($!.backtrace) if $! =~ /redis/i
      nil
    end

    protected

    def do_work(message)
      puts "MESSAGE OFFSET (postback): #{message.offset}"
      event = Consumers::Kafka::PostbackEvent.new(message.value)
      return unless @listen_to_these_events.include?(event.call)

      urls = event.generate_urls
      puts "DUMPING #{urls.size} URLS TO REDIS"
      @redis_queue.jpush(urls)
    end
  end
end
