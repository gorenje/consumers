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

if File.exists?(".env")
  require 'dotenv'
  Dotenv.load
end

Dir[File.join(File.dirname(__FILE__),'config', 'initializers','*.rb')].
  each { |a| require_relative a }

%w[lib routes models lib/consumers lib/kafka].each do |path|
  Dir[File.join(File.dirname(__FILE__), path, "*.rb")].each do |lib|
    require lib.gsub(/\.rb$/, '')
  end
end
