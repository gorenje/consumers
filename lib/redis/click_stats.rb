class RedisClickStats
  attr_reader :connection_pool

  # Since we longer update for every event and cache the commands,
  # we could actually increment in memory and on flush just increment
  # by the aggregated values.

  def initialize(connection_pool)
    @connection_pool = connection_pool
    @pipe_commands = []
  end

  def update(click_event)
    key = "clickstats:cl:#{click_event.campaign_link_id}"

    @pipe_commands << [:zincrby, key, 1, "count"]
    @pipe_commands << [:zincrby, key, 1, "country:#{click_event.country}"]
    @pipe_commands << [:zincrby, key, 1, "platform:#{click_event.platform}"]
    @pipe_commands << [:zincrby, key, 1, "device:#{click_event.device_name}"]
    @pipe_commands << [:zincrby, key, 1, "device_type:#{click_event.device}"]
    (@pipe_commands << [:zincrby, key, 1, "botclick"]) if click_event.is_bot?
    (@pipe_commands << [:zincrby, key, 1, "with_adid"]) if click_event.has_adid?

    flush if @pipe_commands.size > 2000
  end

  def flush
    with_redis do |redis|
      redis.pipelined do |pipe|
        @pipe_commands.each do |cmd|
          pipe.send(cmd.first, *cmd[1..-1])
        end
      end
    end
    @pipe_commands = []
  end

  def conversion(click_event, install_event)
    key = "clickstats:cl:#{click_event.campaign_link_id}"

    @pipe_commands << [:zincrby, key, 1, "conversion"]
    @pipe_commands << [:zincrby, key, 1,
                       "conversion:country:#{install_event.country}"]
    flush if @pipe_commands.size > 2000
  end

  protected

  def with_redis
    connection_pool.with do |redis|
      yield redis
    end
  end
end
