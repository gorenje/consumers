require_relative 'base'

module Consumers
  class Clickstore
    include Consumers::Base
    include Sidekiq::Worker

    sidekiq_options :queue => :clickstore_consumer

    def initialize
      @url_queue = RedisQueue.new($redis.local, :tracking_url_queue)

      @redis_stats            = RedisClickStats.new($redis.click_stats)
      @redis_clickstore       = RedisExpiringSet.new($redis.click_store)
      @listen_to_these_events = ["click"]
    end

    def perform
      $kafka.click.consumer(:group_id => "clicks").tap do |c|
        c.subscribe("clicks")
      end.each_message(:loop_count => 60) do |message|
        do_work(message)
      end
    rescue
      handle_exception($!)
      nil
    end

    protected

    def do_work(message)
      puts "MESSAGE OFFSET (clickstore): #{message.offset}"
      event = Consumers::Kafka::ClickEvent.new(message.value)
      return unless @listen_to_these_events.include?(event.call)
      puts "EVENT DELAY (clickstore) #{event.delay_in_seconds} seconds"

      @redis_clickstore.add_click_event(event)
      @redis_stats.update(event)

      #### TESTING
      puts "DUMPING install URL TO REDIS (clickstore)"
      @url_queue.jpush([Tracking::Event.new.install({:adid => event.adid})])
      ##### END TESTING
    end
  end
end
