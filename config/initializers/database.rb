require 'active_record'

module ConsumerApp
  class DBConfig
    def self.configure
      resolver_kls =
        ActiveRecord::ConnectionAdapters::ConnectionSpecification::
        ConnectionUrlResolver

      ActiveRecord::Base.configurations = {
        "localdb" => (resolver_kls.new(ENV["DATABASE_URL"]).to_hash.
                      merge(:reconnect => true)),
        "clickdb" => (resolver_kls.new(ENV["CLICK_DATABASE_URL"]).to_hash.
                      merge(:reconnect => true))
      }

      ActiveRecord::Base.logger =
        Sinatra::Base.development? ? Logger.new(STDOUT) : nil

      load_models
      establish_connection
    end

    def self.establish_connection
      models.each do |klass|
        klass.establish_connection klass.connection_key
      end
    end

    def self.models
      ObjectSpace.each_object(Class).select do |klass|
        klass < ActiveRecord::Base
      end
    end

    def self.load_models
      Dir[File.join(File.dirname(__FILE__), '..', '..', 'models', '*.rb')].
        sort.each { |a| require a }
    end
  end
end


ActiveSupport.on_load(:active_record) do
  ConsumerApp::DBConfig.configure
  puts "DB connection established for #{ENV['RACK_ENV']}"
end
