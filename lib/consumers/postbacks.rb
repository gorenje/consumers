require_relative 'base'

module Consumers
  class Postbacks
    include Consumers::Base
    include Sidekiq::Worker

    sidekiq_options :queue => :postback_consumer

    attr_reader :redis_queue

    def initialize
      @redis_queue            = RedisQueue.new($redis.local, :url_queue)
      @listen_to_these_events = Postback.unique_events - ["mac"]
    end

    def perform
      $kafka.postback.consumer(:group_id => "postback").tap do |c|
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
      puts "MESSAGE OFFSET (postback): #{message.offset}"
      event = Consumers::Kafka::PostbackEvent.new(message.value)
      return unless @listen_to_these_events.include?(event.call)
      puts "EVENT DELAY (postback) #{event.delay_in_seconds} seconds"

      urls = event.generate_urls
      puts "DUMPING #{urls.size} URLS TO REDIS"
      @redis_queue.jpush(urls)
    end
  end
end
