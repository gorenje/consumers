class User < ActiveRecord::Base
  def self.connection_key
    :localdb
  end

end
