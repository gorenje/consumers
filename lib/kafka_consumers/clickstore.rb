require_relative 'base'

module Consumers
  class Clickstore
    include Consumers::Base
    include Sidekiq::Worker

    sidekiq_options :queue => :clickstore_consumer

    def initialize
      @redis_clickstore       = RedisExpiringSet.new($redis.click_store)
      @listen_to_these_events = ["click"]
    end

    def perform
      start_kafka_stream(:click, "clicks", "clicks", 60)
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
#      @redis_clickstore.add_click_event(event)
    end
  end
end
