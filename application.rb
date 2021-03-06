require 'bundler/setup'
require 'oj_mimic_json'

require 'rack'
require 'sinatra'
require 'sinatra/json'
require 'omniauth'
require 'omniauth-google-oauth2'
require 'net/http/persistent'

require 'erb'
require 'timeout'
require 'ipaddr'
require 'addressable/uri'
require 'cgi'
require 'tilt/erubis'
require 'adtekio_adnetworks'

if File.exists?(".env")
  require 'dotenv'
  Dotenv.load
end

set(:environment,   ENV['RACK_ENV']) unless ENV['RACK_ENV'].nil?

%w[config/initializers lib lib/kafka_consumers lib/schedulers
   lib/kafka_events lib/redis models routes].
  each do |path|
  Dir[File.join(File.dirname(__FILE__), path, "*.rb")].each do |lib|
    require lib.gsub(/\.rb$/, '')
  end
end
