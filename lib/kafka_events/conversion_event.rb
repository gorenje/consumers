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

      # this takes one argument so that UrlParser can use it. For
      # Postback events it's necessary to pass in the postback, in this
      # case, the user_id is attached to the event.
      def network_user(_ = nil)
        @user ||=
          NetworkUser.where(:network         => network,
                            :user_identifier => adid,
                            :user_id         => user_id).first
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
          UrlConfigParser.new(self, postback).generate
        end.compact.reject { |h| h[:url].blank? }
      end
    end
  end
end
