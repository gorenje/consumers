require_relative 'base'

module Consumers
  class Clickstats
    include Consumers::Base
    include Sidekiq::Worker

    sidekiq_options :queue => :clickstats_consumer

    def initialize
      @redis_stats = RedisClickStats.new($redis.click_stats)
      handle_these_events(["click"])
    end

    def perform
      start_kafka_stream(:clickstats, "clickstats", "clicks", 400)
    rescue
      handle_exception($!)
      nil
    end

    protected

    def do_work(message)
      Consumers::Kafka::ClickEvent.new(message.value).tap do |event|
        handle_event(event)
      end
    end

    def handle_event(event)
      @redis_stats.update(event)
    end

    def done_handling_messages
      @redis_stats.flush
    end
  end
end
