require 'sidekiq/api'

module Scheduler
  class Conversion
    include Sidekiq::Worker

    attr_reader :redis_queue, :batch_size, :job_life_time
    attr_reader :sleep_between_execution, :started_at

    def initialize(batch_size = 200, job_life_time = 58, sleep_between_execution = 1)
      @batch_size              = batch_size
      @job_life_time           = job_life_time
      @sleep_between_execution = sleep_between_execution
      @started_at              = Time.now
    end

    def perform
      begin
        if pending_jobs == 0 && running_jobs == 0
          Consumers::Conversion.perform_async
          sleep(1) while running_jobs == 0 && pending_jobs == 0 && !time_up?
        end
        sleep(sleep_between_execution) if sleep_between_execution > 0
      end while !time_up?
    end

    private

    def time_up?
      (Time.now - started_at) > job_life_time
    end

    def running_jobs
      Sidekiq::Workers.new.select do |a,t,m|
        m['payload']['class'] == 'Consumers::Conversion'
      end.size
    end

    def pending_jobs
      Sidekiq::Stats.new.queues["conversion_consumer"] || 0
    end
  end
end
