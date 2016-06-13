module Consumers
  module Base
    def handle_exception(exp)
      puts "Preventing retries on error: #{exp}"
      unless exp.to_s =~ /No partitions assigned/
        puts(exp.backtrace) if exp.to_s =~ /redis/i
      end
    end

    def start_kafka_stream(name, group_id, topics, loop_count)
      $kafka[name].consumer(:group_id => group_id).tap do |c|
        [topics].flatten.each { |topic| c.subscribe(topic) }
      end.each_message(:loop_count => loop_count) do |message|
        do_work(message)
      end
    end
  end
end
