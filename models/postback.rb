class Postback < ActiveRecord::Base
  def self.unique_events
    select("distinct event").map(&:event)
  end

  def netcfg
    OpenStruct.new(env["netcfg"] || {})
  end

  def self.find_postback_for_conversion(click, event)
    Postback.where(:network    => click.network,
                   :user_id    => click.user_id,
                   :event      => event,
                   :store_user => true)
  end
end
