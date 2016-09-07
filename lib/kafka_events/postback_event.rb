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

      def postbacks(cache = nil)
        @postbacks ||= if cache
                         cache[call]["all"] + cache[call][platform]
                       else
                         Postback.where(:event    => call,
                                        :platform => ["all", platform]).to_a
                       end
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

      # Postbacks have a user_id which is the original customer that created
      # this postback. The problem is that events don't have a user_id, so
      # there is no way to differentiate postbacks on a customer level.
      # Other than if a user (i.e. network user, i.e. a user created by
      # a conversion which does contain customer information) is required.
      # If a user is required, the postback tries to retrieve a network user
      # using the customer information to limit the user retrieved --> no
      # user found, no postback.
      def generate_urls(cache = nil)
        postbacks(cache).map do |postback|
          # reject postbacks that require a user, but there
          # isn't a user defined. This generally means that the
          # user wasn't acquired over the corresponding network.
          next if postback.user_required? && user_not_defined?(postback)

          UrlConfigParser.new(self, postback).generate
        end.flatten.compact.reject { |h| h[:url].blank? }
      end
    end
  end
end
