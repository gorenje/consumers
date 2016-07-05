require 'kafka'
require_relative './host_handler'

opts = {
  :seed_brokers => ["#{$hosthandler.kafka.host}:9092"],
  :logger       => Logger.new($stderr),
}
opts[:logger].level = Logger::WARN if ENV['RACK_ENV'] == 'production'

$kafka = OpenStruct.new.tap do |os|
  ["attribution", "postback", "clickstore", "clickstats",
   "conversion", "pbstats"].each do |client_id|
    os[client_id] = Kafka.new(opts.merge(:client_id => client_id))
  end
end
