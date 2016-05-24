class Click < ActiveRecord::Base
  self.primary_key = :id

  def self.connection_key
    :clickdb
  end

  def lookup_key=(val)
    write_attribute(:lookup_key, [val].pack('H*'))
  end

  def lookup_key
    read_attribute(:lookup_key).try(:unpack, 'H*').try(:first)
  end
end
