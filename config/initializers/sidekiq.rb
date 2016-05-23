require 'sidekiq'
require 'sidekiq/web'
require 'sidekiq-cron'
require 'sidekiq/cron/web'

require_relative 'redis'

cron_jobs = [
             {
               'name'  => 'url_worker_scheduler',
               'class' => 'Scheduler::Url',
               'cron'  => '*/1 * * * *',
               'args'  => nil
             },
             {
               'name'  => 'postback_consumer_scheduler',
               'class' => 'Scheduler::Postbacks',
               'cron'  => '*/1 * * * *',
               'args'  => nil
             },
]

module EccrineAnalytics
  class ActiveRecordLocalMiddleware
    def call(worker, job, queue)
      yield
    ensure
      ActiveRecord::Base.clear_active_connections! if defined?(::ActiveRecord)
    end
  end
end

Sidekiq.configure_server do |config|
  config.redis = { :url => ENV['REDISTOGO_URL'], :driver => :hiredis,
    :size => (ENV["REDIS_POOL_SIZE"] || 5).to_i }

  Sidekiq::Cron::Job.load_from_array cron_jobs

  # config.server_middleware do |chain|
  #   chain.add EccrineAnalytics::ActiveRecordLocalMiddleware
  # end
end

Sidekiq.configure_client do |config|
  config.redis = { :url => ENV['REDISTOGO_URL'], :driver => :hiredis, :size => (ENV["REDIS_POOL_SIZE"] || 5).to_i }
end

Sidekiq.default_worker_options = { 'backtrace' => true }

class SidekiqWebNoSessions < Sidekiq::Web
  disable :sessions
end
