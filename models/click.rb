class Click < ActiveRecord::Base
  def self.connection_key
    :clickdb
  end

end
