module AdtekioTracking
  module Http

    def send_request(path, params)
      uri = Addressable::URI.new
      uri.query_values = params

      doit(*http_client(URI.parse("%s%s?%s" % [endpoint, path, uri.query])))
    end

    def doit(request, http)
      begin
        response = http.request(request)
      rescue Timeout::Error, Errno::EINVAL, Errno::ECONNRESET, EOFError,
        Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError,
        Net::ProtocolError => e
        raise AdtekioTracking::TrackingError.
          new("Payment API could not connect to server", e)
      end

      if response.code != '200'
        raise(AdtekioTracking::TrackingError,
              "Payment API returned error #{response.code}")
      end
      response.body
    end

    def http_client(uri)
      request = Net::HTTP::Get.new(uri)

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      http.open_timeout = timeout
      http.read_timeout = timeout

      [request, http]
    end

    def timeout
      AdtekioTracking.configure.timeout
    end

    def endpoint
      AdtekioTracking.configure.endpoint
    end
  end
end
