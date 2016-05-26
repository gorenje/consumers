require_relative 'event'

module Consumers
  module Kafka
    class ClickEvent < Consumers::Kafka::Event
      def initialize(payload)
        super(payload)
      end

      [:created_at, :network, :attr_window_from, :attr_window_till,
       :campaign, :ad, :adgroup, :adid, :campaign_link_id, :click,
       :idfa_comb,:lookup_key, :partner_data, :redirect_url].each do |attr|
        define_method(attr) do
          (params[attr] || []).first
        end
      end

      def attribution_window
        DateTime.parse(attr_window_from)..DateTime.parse(attr_window_till)
      end

      def max_age
        DateTime.parse(attr_window_till)
      end

      def is_bot?
        !bot_name.blank?
      end

      def has_adid?
        !idfa_comb.blank?
      end
    end
  end
end
