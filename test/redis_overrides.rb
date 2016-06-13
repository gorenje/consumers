class RedisExpiringSet
  def clear!
    connection_pool.with { |r| r.keys("*").each { |key| r.del(key) } }
  end

  def keys
    connection_pool.with { |r| r.keys("*") }
  end

  def method_missing(name, *args, &block)
    connection_pool.with { |r| r.send(name, *args) }
  end
end

class RedisClickStats
  def clear!
    connection_pool.with { |r| r.keys("*").each { |key| r.del(key) } }
  end

  def keys
    connection_pool.with { |r| r.keys("*") }
  end

  def method_missing(name, *args, &block)
    connection_pool.with { |r| r.send(name, *args) }
  end
end
