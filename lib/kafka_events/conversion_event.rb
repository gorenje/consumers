require_relative 'event'

module Consumers
  module Kafka
    class ConversionEvent < Consumers::Kafka::Event
      def initialize(payload)
        super(payload)
      end

      def click
        @click ||= Consumers::Kafka::ClickEvent.new(params[:click].first)
      end

      def install
        @install ||= Consumers::Kafka::InstallEvent.new(params[:install].first)
      end

      def platform
        install.platform
      end

      def network
        click.network
      end

      def adid
        click.adid || install.adid
      end
      alias_method :idfa, :adid

      def device_id
        adid
      end

      def user_id
        click.user_id
      end

      def appleid
        "MISSING"
      end

      def bundleid
        "MISSING"
      end

      def postbacks
        @postbacks ||=
          Postback.where(:network  => network,
                         :event    => call,
                         :user_id  => user_id,
                         :platform => ["all", platform]).to_a
      end

      def generate_urls
        postbacks.map do |postback|
          # conversion events can't require a user, conversion events
          # define the user (assumed to be after the postback is done)
          next if postback.user_required?
          UrlConfigParser.new(self.click, postback).generate
        end.compact.reject { |h| h[:url].blank? }
      end
    end
  end
end
