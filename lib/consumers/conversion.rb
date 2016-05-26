module Consumers
  class Conversion
    include Sidekiq::Worker

    sidekiq_options :queue => :conversion_consumer

    def initialize
      @redis_queue            = RedisQueue.new($redis_pool, :url_queue)
      @listen_to_these_events = ["mac"]
    end

    def perform
      consumer = $kafka.conversion.consumer(:group_id => "conversion")

      consumer.subscribe("inapp")
      consumer.each_message(:loop_count => 15) do |message|
        puts "MESSAGE OFFSET (conversion): #{message.offset}"
        event = Consumers::Kafka::ConversionEvent.new(message.value)
        next unless @listen_to_these_events.include?(event.call)
        next if event.params[:click].nil? or event.params[:install].nil?

        urls = event.generate_urls
        puts "DUMPING #{urls.size} URLS TO REDIS"
        @redis_queue.jpush(urls)
      end
    rescue
      puts "Preventing retries on error: #{$!}"
      puts $!.backtrace # ) if $! =~ /redis/i
      nil
    end
  end
end
