require_relative 'base'

module Consumers
  class Clickstats
    include Consumers::Base
    include Sidekiq::Worker

    sidekiq_options :queue => :clickstats_consumer

    def initialize
      @redis_stats            = RedisClickStats.new($redis.click_stats)
      @listen_to_these_events = ["click"]
    end

    def perform
      start_kafka_stream(:clickstats, "clickstats", "clicks", 600)
    rescue
      handle_exception($!)
      nil
    end

    protected

    def do_work(message)
      event = Consumers::Kafka::ClickEvent.new(message.value)
      return(event) unless @listen_to_these_events.include?(event.call)
      handle_event(event)
      event
    end

    def handle_event(event)
      @redis_stats.update(event)
    end
  end
end
