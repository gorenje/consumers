module AdtekioTracking
  class Configuration
    attr_accessor :endpoint, :timeout

    def initialize
      @endpoint = "https://inapp.adtek.io"
      @timeout  = 25 # seconds
    end
  end
end
