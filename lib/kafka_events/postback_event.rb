require_relative 'event'

module Consumers
  module Kafka
    class PostbackEvent < Consumers::Kafka::Event
      def initialize(payload)
        super(payload)
        params[:mid] = ""
        @users = {}
      end

      def revenue
        "MISSING"
      end

      def appleid
        "MISSING"
      end

      def bundleid
        "MISSING"
      end

      def device_id
        adid || params[:mid]
      end

      def android?
        platform == "android"
      end

      alias_method :trigger_stamp, :ts

      def postbacks
        @postbacks ||=
          Postback.where(:event    => call,
                         :platform => ["all", platform]).to_a
      end

      def network_user(postback)
        @users[postback.user_id] ||=
          if adid.blank?
            nil
          else
            NetworkUser.for_postback_and_identifier(postback,adid)
          end
      end

      def user_not_defined?(postback)
        network_user(postback).nil?
      end

      def generate_urls
        postbacks.map do |postback|
          # reject postbacks that require a user, but there
          # isn't a user defined. This generally means that the
          # user wasn't acquired over the corresponding network.
          next if postback.user_required? && user_not_defined?(postback)

          UrlConfigParser.new(self, postback).generate
        end.compact.reject { |h| h[:url].blank? }
      end
    end
  end
end
