require_relative 'event'

module Consumers
  module Kafka
    class PbstatsEvent < Consumers::Kafka::Event
      def initialize(payload)
        super(payload)
      end

      def handlable?
        !response_code.blank? && !postback_id.blank?
      end

      def response_code
        (params[:rc] || []).first
      end

      def postback_id
        (params[:pbid] || []).first
      end
    end
  end
end
