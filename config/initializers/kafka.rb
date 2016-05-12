require 'kafka'

logger = Logger.new($stderr)
$kafka = Kafka.new(:seed_brokers => ["#{ENV['KAFKA_HOST']}:9092"],
                   :logger => logger)

$kafka_postback_consumer = $kafka.consumer(:group_id => "postback")
$kafka_attribution_consumer = $kafka.consumer(:group_id => "attribution")
