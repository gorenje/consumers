module Consumers
  class Attribution
    include Sidekiq::Worker

    sidekiq_options :queue => :attribution_consumer

    def initialize
      @redis_clickstore = RedisExpiringSet.new($redis_click_pool)
      @listen_to_these_events = ["ist"]
    end

    def perform
      consumer = $kafka.attribution.consumer(:group_id => "attribution")

      consumer.subscribe("inapp")
      consumer.each_message(:loop_count => 15) do |message|
        puts "MESSAGE OFFSET (attribution): #{message.offset}"
        event = Consumers::Kafka::InstallEvent.new(message.value)
        next unless @listen_to_these_events.include?(event.call)

        results = @redis_clickstore.
          find_by_lookup_keys(event.lookup_keys, event.time - 300, event.time)

        unless results.empty?
          puts "FOUND MATCH"
          key,values = results.first
          click_payload = values.first
          @redis_clickstore.remove_value_from_key(key, click_payload)

          click = Consumers::Kafka::ClickEvent.new(click_payload)
          Postback.find_postback_for_conversion(click, "mac").
            each do |postback|
            NetworkUser.create_new_for_conversion(click,event,postback)
          end

          AdtekioTracking::Events.new.
            conversion({:click => click.payload, :install => event.payload})
        end
      end
    rescue
      puts "Preventing retries on error: #{$!}"
      puts $!.backtrace # ) if $! =~ /redis/i
      nil
    end
  end
end
