require 'addressable/uri'

require 'adtekio_tracking/configuration'
require 'adtekio_tracking/http'
require 'adtekio_tracking/tracking_error'
require 'adtekio_tracking/events'

module AdtekioTracking
  extend self

  def configuration
    @configuration ||= Configuration.new
  end

  def configure
    config = configuration
    block_given? ? yield(config) : config
    config
  end
end
