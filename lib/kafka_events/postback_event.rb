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
          (Postback.where(:network       => network,
                          :event         => call,
                          :platform      => ["all", platform],
                          :user_required => true) +
           Postback.where(:event         => call,
                          :platform      => ["all", platform],
                          :user_required => false)).to_a
      end

      def network_user(postback)
        ## Only called if necessary and buffer the result
        @users[postback.user_id] ||=
          if network.blank? && adid.blank?
            OpenStruct.new({})
          else
            NetworkUser.where(:network         => network,
                              :user_identifier => adid,
                              :user_id         => postback.user_id).first
          end
      end

      def generate_urls
        postbacks.map do |postback|
          UrlConfigParser.new(self, postback).generate
        end.compact.reject { |h| h[:url].blank? }
      end
    end
  end
end
