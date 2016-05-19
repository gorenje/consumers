require 'adtekio_tracking'

AdtekioTracking.configure do |config|
  config.endpoint = ENV['TRACKING_HOST']
end
