require 'sidekiq/api'

module Scheduler
  class Postbacks
    include Sidekiq::Worker

    attr_reader :redis_queue, :batch_size, :job_life_time, :sleep_between_execution

    def initialize(batch_size = 200, job_life_time = 58, sleep_between_execution = 1)
      @batch_size              = batch_size
      @job_life_time           = job_life_time
      @sleep_between_execution = sleep_between_execution
    end

    def perform
      started_at = Time.now
      begin
        if pending_jobs == 0 && running_jobs == 0
          Consumers::Postbacks.perform_async
          sleep(1) while running_jobs == 0 && pending_jobs == 0
        end
        sleep(sleep_between_execution) if sleep_between_execution > 0
      end while (Time.now - started_at) < job_life_time
    end

    private

    def running_jobs
      Sidekiq::Workers.new.select do |a,t,m|
        m['payload']['class'] == 'Consumers::Postbacks'
      end.size
    end

    def pending_jobs
      Sidekiq::Stats.new.queues["postback_consumer"] || 0
    end
  end
end
