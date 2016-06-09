class Postback < ActiveRecord::Base
  def self.unique_events
    select("distinct event").map(&:event)
  end

  def netcfg
    OpenStruct.new(env["netcfg"] || {})
  end

  def self.where_we_need_to_store_user(click)
    Postback.where(:network    => click.network,
                   :user_id    => click.user_id,
                   :event      => "mac",
                   :store_user => true)
  end
end
