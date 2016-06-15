require 'kafka'

opts = {
  :seed_brokers => ["#{ENV['KAFKA_HOST']}:9092"],
  :logger       => Logger.new($stderr),
}
opts[:logger].level = Logger::WARN if ENV['RACK_ENV'] == 'production'

$kafka = OpenStruct.new.tap do |os|
  ["attribution", "postback", "clickstore", "clickstats",
   "conversion"].each do |client_id|
    os[client_id] = Kafka.new(opts.merge(:client_id => client_id))
  end
end
