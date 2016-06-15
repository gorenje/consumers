module Consumers
  module Base
    def handle_exception(exp)
      puts "#{self.class.name}: Preventing retries on error: #{exp}"
      unless exp.to_s =~ /No partitions assigned/
        puts(exp.backtrace) if exp.to_s =~ /redis/i
      end
    end

    def start_kafka_stream(name, group_id, topics, loop_count)
      last_good_known_message = OpenStruct.new(:offset => -1)
      last_good_known_event = OpenStruct.new(:delay_in_seconds => -1)

      begin_handling_messages

      $kafka[name].consumer(:group_id => group_id).tap do |c|
        [topics].flatten.each { |topic| c.subscribe(topic) }
      end.each_batch(:loop_count => loop_count, :max_wait_time => 0) do |batch|
        batch.messages.each do |message|
          last_good_known_message = message
          last_good_known_event = do_work(message)
        end
      end

      done_handling_messages

      $librato_queue.
        add("#{name}_event_delay" => last_good_known_event.delay_in_seconds)
      $librato_queue.add("#{name}_offset" => last_good_known_message.offset)
    end

    def update_cache(interval, &block)
      t = Time.now
      if (@cache_timestamp + interval) < t
        @cache_timestamp = t
        yield
      end
    end

    def initialize_cache(which_one)
      @cache_timestamp = Time.now
      @postback_cache  = Postback.send(which_one)
    end

    def begin_handling_messages
    end

    def done_handling_messages
    end
  end
end
