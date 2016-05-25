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

      def is_bot?
        !bot_name.blank?
      end

      def has_adid?
        !idfa_comb.blank?
      end

      def to_hash
        {
          "created_at"         => DateTime.parse(created_at),
          "network"            => network,
          "campaign"           => campaign,
          "adgroup"            => adgroup,
          "ad"                 => ad,
          "platform"           => platform,
          "click"              => click,
          "partner_data"       => partner_data,
          "matched"            => false,
          "adid"               => adid,
          "idfa_comb"          => idfa_comb,
          "attribution_window" => attribution_window,
          "lookup_key"         => lookup_key,
          "campaign_link_id"   => campaign_link_id,
          "country"            => country,
          "device_name"        => device_name,
          "redirect_url"       => redirect_url,
          "device_type"        => device,
          "bot_name"           => bot_name
        }
      end
    end
  end
end
