require_relative 'base'

module Consumers
  class Clickstore
    include Consumers::Base
    include Sidekiq::Worker

    sidekiq_options :queue => :clickstore_consumer

    def initialize
      @clickstore = RedisExpiringSet.new($redis.click_store)
      handle_these_events(["click"])
    end

    def perform
      start_kafka_stream(:clickstore, "clicks", "clicks", 600)
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
      @clickstore.add_click_event(event)
    end

    def done_handling_messages
      @clickstore.flush
    end
  end
end
