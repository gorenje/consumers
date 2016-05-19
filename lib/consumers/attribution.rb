module Consumers
  class Attribution
    include Sidekiq::Worker

    sidekiq_options :queue => :batch_attribution

    def initialize
    end

    def perform
      $kafka_attribution_consumer.subscribe("inapp")
      $kafka_attribution_consumer.each_message do |message|
        event = Consumers::Kafka::Event.new(message.value)
        ## TODO do something here.
      end
    rescue Exception => e
      puts e.message
      puts e.backtrace
    end

  end
end
