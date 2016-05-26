module Consumers
  class Clickstore
    include Sidekiq::Worker

    sidekiq_options :queue => :clickstore_consumer

    def initialize
      @redis_stats = RedisClickStats.new($redis_click_pool)
      @redis_clickstore = RedisExpiringSet.new($redis_click_pool)
      @listen_to_these_events = ["click"]
    end

    def perform
      consumer = $kafka.click.consumer(:group_id => "clicks")

      consumer.subscribe("clicks")
      consumer.each_message(:loop_count => 15) do |message|
        puts "MESSAGE OFFSET (clickstore): #{message.offset}"
        event = Consumers::Kafka::ClickEvent.new(message.value)
        next unless @listen_to_these_events.include?(event.call)

        @redis_clickstore.add_click_event(event)
        @redis_stats.update(event)
      end
    rescue
      puts "Preventing retries on error: #{$!}"
      puts($!.backtrace) if $! =~ /redis/i
      nil
    end
  end
end
