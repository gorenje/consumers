class Postback < ActiveRecord::Base
  def self.unique_events
    select("distinct event").map(&:event)
  end

  def netcfg
    OpenStruct.new(env["netcfg"] || {})
  end
end
