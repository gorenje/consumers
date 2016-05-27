require 'cgi'

module Consumers
  module Kafka
    class Event
      attr_reader :type, :payload, :params, :meta

      def initialize(payload)
        @payload = payload

        typestr,meta,params = @payload.split(' ')
        @type   = typestr.split('/').last
        @params = CGI.parse(params).symbolize_keys
        @meta   = CGI.parse(meta).symbolize_keys
      end

      [:device, :country, :ip, :platform, :ts, :bot_name,
       :device_name].each do |attr|
        define_method(attr) do
          (meta[attr] || []).first
        end
      end

      [:network].each do |attr|
        define_method(attr) do
          (params[attr] || []).first
        end
      end

      alias_method :call, :type

      def adid
        adid = (params[:adid] || []).first
        (adid && adid != "null" &&
         adid != "undefined" && !(adid =~ /^[0-]+$/) &&
         adid != "" && adid) || nil
      end
      alias_method :idfa, :adid

      def gadid
        gadid = (params[:gadid] || []).first
        (gadid && gadid != "null" &&
         gadid != "undefined" && !(gadid =~ /^[0-]+$/) &&
         gadid != "" && gadid) || nil
      end

      def gadid_has_valid_format?
        !!(/^[a-f0-9]{4}([a-f0-9]{4}-){4}[a-f0-9]{12}$/i =~ gadid)
      end

      def uuid
        uuid = (params[:uuid] || []).first
        (uuid && uuid != "null" &&
         uuid != "undefined" && !(uuid =~ /^[0-]+$/) &&
         uuid != "" && uuid) || nil
      end

      def time
        @time ||= Time.at(ts.to_i)
      end
    end
  end
end
