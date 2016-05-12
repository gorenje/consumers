ENV['env'] ||= 'development'

require 'rubygems'
require 'bundler'

begin
  Bundler.setup(:default, ENV['env'])
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end

if File.exists?(".env")
  require 'dotenv'
  Dotenv.load
end

require 'rake'
require 'yaml'

task :environment do
  require_relative 'application'
end

# to generate an initial .env, don't need a database
if ENV['DATABASE_URL']
  require 'active_record_migrations'
  ActiveRecordMigrations.configure do |c|
    c.database_configuration = ActiveRecord::Base.configurations
    c.yaml_config = 'config/database.yml'
    c.environment = ENV['env']
    c.db_dir = 'config/db'
    c.migrations_paths = ['config/db/migrations']
  end
  ActiveRecordMigrations.load_tasks
end

begin
  task :default => :test
  require 'rake/testtask'
  Rake::TestTask.new(:test) do |test|
    test.libs << 'lib' << 'test'
    test.pattern = 'test/**/*_test.rb'
    test.verbose = true
  end
rescue Exception => e
  # Bundler not installed on the server.
end

Dir[File.join(File.dirname(__FILE__), 'lib', 'tasks','*.rake')].each { |f| load f }
