require_relative 'event'
require 'digest/md5'
require 'digest/sha1'

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

      def device_id
        adid
      end

      def network_user
        @user ||= NetworkUser.where(:nework => network,
                                    :user_identifier => adid).first
      end

      def postbacks
        @postbacks ||=
          Postback.where(:network       => network,
                         :event         => call,
                         :platform      => ["all", platform]).to_a
      end

      def generate_urls
        postbacks.map do |postback|
          UrlConfigParser.new(self, postback).generate
        end.compact.reject { |h| h[:url].blank? }
      end
    end
  end
end
