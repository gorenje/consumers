require_relative 'base'

module Consumers
  class Pbstats
    include Consumers::Base
    include Sidekiq::Worker

    sidekiq_options :queue => :pbstats_consumer

    attr_reader :redis_queue

    def initialize
      @redis_stats = RedisClickStats.new($redis.click_stats)
      handle_these_events(["pob"])
    end

    def perform
      start_kafka_stream(:pbstats, "pbstats", "inapp", 600)
    rescue
      handle_exception($!)
      nil
    end

    protected

    def do_work(message)
      Consumers::Kafka::PbstatsEvent.new(message.value).tap do |event|
        handle_event(event) if event.handlable?
      end
    end

    def handle_event(event)
      @redis_stats.update_postback(event)
    end

    def done_handling_messages
      @redis_stats.flush
    end
  end
end
