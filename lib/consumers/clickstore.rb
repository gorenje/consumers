module Consumers
  class Clickstore
    include Sidekiq::Worker

    sidekiq_options :queue => :clickstore_consumer

    def initialize
      @redis_stats = RedisClickStats.new($redis_click_pool)
      @listen_to_these_events = ["click"]
    end

    def perform
      click_consumer = $kafka_clicks.consumer(:group_id => "clicks")

      click_consumer.subscribe("clicks")
      click_consumer.each_message(:loop_count => 15) do |message|
        puts "MESSAGE OFFSET: #{message.offset}"
        event = Consumers::Kafka::ClickEvent.new(message.value)
        next unless @listen_to_these_events.include?(event.call)
        @redis_stats.update(event)
      end
    rescue
      puts "Preventing retries on error: #{$!}"
      puts($!.backtrace) if $! =~ /redis/i
      nil
    end
  end
end
