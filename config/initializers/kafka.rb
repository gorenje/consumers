require 'kafka'

opts = {
  :seed_brokers => ["#{ENV['KAFKA_HOST']}:9092"],
  :logger       => Logger.new($stderr),
}

$kafka = OpenStruct.new.tap do |os|
  ["attribution", "postback", "click", "conversion"].each do |client_id|
    os[client_id] = Kafka.new(opts.merge(:client_id => client_id))
  end
end
