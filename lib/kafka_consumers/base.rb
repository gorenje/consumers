module Consumers
  module Base
    def handle_exception(exp)
      puts "Preventing retries on error: #{exp}"
      unless exp.to_s =~ /No partitions assigned/
        puts(exp.backtrace) if exp.to_s =~ /redis/i
      end
    end
  end
end
