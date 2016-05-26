class RedisClickStats
  attr_reader :connection_pool

  def initialize(connection_pool)
    @connection_pool = connection_pool
  end

  def update(click_event)
    key = "clickstats:cl:#{click_event.campaign_link_id}"

    with_redis do |redis|
      redis.pipelined do |pipe|
        pipe.zincrby(key, 1, "count")
        pipe.zincrby(key, 1, "country:#{click_event.country}")
        pipe.zincrby(key, 1, "platform:#{click_event.platform}")
        pipe.zincrby(key, 1, "device:#{click_event.device_name}")
        pipe.zincrby(key, 1, "device_type:#{click_event.device}")
        pipe.zincrby(key, 1, "botclick") if click_event.is_bot?
        pipe.zincrby(key, 1, "with_adid") if click_event.has_adid?
      end
    end
  end

  def conversion(click_event, install_event)
    key = "clickstats:cl:#{click_event.campaign_link_id}"

    with_redis do |redis|
      redis.pipelined do |pipe|
        pipe.zincrby(key, 1, "conversion")
        pipe.zincrby(key, 1, "conversion:country:#{install_event.country}")
      end
    end
  end

  protected

  def with_redis
    connection_pool.with do |redis|
      yield redis
    end
  end
end
