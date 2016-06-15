module Consumers
  module Base
    def handle_exception(exp)
      puts "#{self.class.name}: Preventing retries on error: #{exp}"
      unless exp.to_s =~ /No partitions assigned/
        puts(exp.backtrace) if exp.to_s =~ /redis/i
      end
    end

    def start_kafka_stream(name, group_id, topics, loop_count)
      $kafka[name].consumer(:group_id => group_id).tap do |c|
        [topics].flatten.each { |topic| c.subscribe(topic) }
      end.each_batch(:loop_count => loop_count) do |batch|
        batch.messages.each do |message|
          $librato_queue.add("#{name}_offset" => message.offset)
          do_work(message)
        end
      end
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
  end
end
