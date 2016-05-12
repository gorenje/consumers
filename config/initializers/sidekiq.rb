require 'sidekiq'
require 'sidekiq/web'
require 'sidekiq-cron'
require 'sidekiq/cron/web'

require_relative 'redis'

cron_jobs = [{
               'name'  => 'postback_consumer',
               'class' => 'Consumers::Postback',
               'cron'  => '*/1 * * * *',
               'args'  => nil
             },
             {
               'name'  => 'batch_scheduler',
               'class' => 'BatchScheduler',
               'cron'  => '*/1 * * * *',
               'args'  => nil
             },
             {
               'name'  => 'attribution_consumer',
               'class' => 'Consumers::Attribution',
               'cron'  => '*/1 * * * *',
               'args'  => nil
             }]


Sidekiq.configure_server do |config|
  config.redis = { :url => ENV['REDISTOGO_URL'], :driver => :hiredis, :size => (ENV["REDIS_POOL_SIZE"] || 5).to_i }

  Sidekiq::Cron::Job.load_from_array cron_jobs
end

Sidekiq.configure_client do |config|
  config.redis = { :url => ENV['REDISTOGO_URL'], :driver => :hiredis, :size => (ENV["REDIS_POOL_SIZE"] || 5).to_i }
end

Sidekiq.default_worker_options = { 'backtrace' => true }
