require_relative 'base'

module Consumers
  class Clickstore
    include Consumers::Base
    include Sidekiq::Worker

    sidekiq_options :queue => :clickstore_consumer

    def initialize
      @clickstore             = RedisExpiringSet.new($redis.click_store)
      @listen_to_these_events = ["click"]
    end

    def perform
      start_kafka_stream(:clickstore, "clicks", "clicks", 600)
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
      @clickstore.add_click_event(event)
    end

    def done_handling_messages
      @clickstore.flush
    end
  end
end
