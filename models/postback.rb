class Postback < ActiveRecord::Base
  def self.unique_events
    select("distinct event").map(&:event)
  end

  def netcfg
    OpenStruct.new(env["netcfg"] || {})
  end

  def self.cache_for_attribution_consumer
    Hash.new do |h,k|
      h[k] = Hash.new do |h1,k1|
        h1[k1] = []
      end
    end.tap do |cache|
      Postback.where(:event      => "mac",
                     :store_user => true).each do |pb|
        cache[pb.network][pb.user_id] << pb
      end
    end
  end

  def self.cache_for_postback_event
    Hash.new do |h,k|
      h[k] = Hash.new do |h1,k1|
        h1[k1] = []
      end
    end.tap do |cache|
      Postback.all.each do |pb|
        cache[pb.event][pb.platform] << pb
      end
    end
  end

  def self.cache_for_conversion_event
    Hash.new do |h,k|
      h[k] = Hash.new do |h1,k1|
        h1[k1] = Hash.new do |h2,k2|
          h2[k2] = Hash.new do |h3,k3|
            h3[k3] = []
          end
        end
      end
    end.tap do |cache|
      Postback.all.each do |pb|
        cache[pb.network][pb.event][pb.user_id][pb.platform] << pb
      end
    end
  end
end
