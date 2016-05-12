require 'sidekiq/api'

class BatchScheduler
  include Sidekiq::Worker

  attr_reader :redis_queue, :batch_size, :job_life_time, :sleep_between_execution

  def initialize(batch_size = 200, job_life_time = 58, sleep_between_execution = 1)
    @redis_queue             = RedisQueue.new($redis_pool, :click_queue)
    @batch_size              = batch_size
    @job_life_time           = job_life_time
    @sleep_between_execution = sleep_between_execution
  end

  def perform
    started_at = Time.now
    begin
      pending_items = redis_queue.size
      required_jobs = (pending_items / batch_size.to_f).ceil - pending_jobs
      required_jobs.times do
        UrlWorker.perform_async(batch_size)
      end
      sleep(sleep_between_execution) if sleep_between_execution > 0
    end while (Time.now - started_at) < job_life_time
  end

  private

  def pending_jobs
    stats = Sidekiq::Stats.new
    stats.queues["batch"] || 0
  end
end
