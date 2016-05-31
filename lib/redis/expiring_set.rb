class RedisExpiringSet

  attr_reader :connection_pool

  def initialize(connection_pool)
    @connection_pool = connection_pool
  end

  def add(key, values, time = Time.now)
    time = time.to_i
    with_redis do |redis|
      redis.pipelined do
        values.each { |value| redis.zadd key, time, value }
      end
    end
  end

  def add_click_event(event)
    add(event.lookup_key, [event.payload], event.max_age)
    expire!(event.lookup_key)
  end

  def expire!(key)
    with_redis do |redis|
      redis.pipelined do
        redis.zremrangebyscore key, 0, Time.now.to_i
        # redis.expire @key, @expire_after
      end
    end
  end

  def delete!(key)
    with_redis do |redis|
      redis.del key
    end
  end

  def remove_value_from_key(key, value)
    with_redis do |redis|
      redis.zrem key, value
    end
  end

  def find_by_lookup_keys(keys, start_time, end_time)
    keys.each do |key|
      with_redis do |redis|
        r = redis.zrangebyscore(key, start_time.to_i, end_time.to_i)
        return({ key => r }) unless r.nil?
      end
    end
    {}
  end

  # def find_by_lookup_keys(keys, start_time, end_time)
  #   with_redis do |redis|
  #     Hash[keys.zip(redis.pipelined do |pipe|
  #                     keys.each do |key|
  #                       pipe.zrangebyscore(key, start_time.to_i,
  #                                          end_time.to_i) || []
  #                     end
  #                   end)].reject { |_,v| v.empty? }
  #   end
  # end

  protected

  def with_redis
    connection_pool.with do |redis|
      yield redis
    end
  end
end
