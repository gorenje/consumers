require_relative 'base'

module Consumers
  class Clickstore
    include Consumers::Base
    include Sidekiq::Worker

    sidekiq_options :queue => :clickstore_consumer

    def initialize
      @redis_queue            = RedisQueue.new($redis_pool, :url_queue)

      @redis_stats            = RedisClickStats.new($redis_click_pool)
      @redis_clickstore       = RedisExpiringSet.new($redis_click_pool)
      @listen_to_these_events = ["click"]
    end

    def perform
      $kafka.click.consumer(:group_id => "clicks").tap do |c|
        c.subscribe("clicks")
      end.each_message(:loop_count => 15) do |message|
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

      @redis_clickstore.add_click_event(event)
      @redis_stats.update(event)

      #### TESTING
      url = {
        :url => "https://inapp.adtek.io/t/ist?adid=ECC27E57-1605-2714-CAFE-13DC6DFB742F",
        :body => nil, :header => nil
      }
      puts "DUMPING install URL TO REDIS (clickstore)"
      @redis_queue.jpush([url])
    end
  end
end
