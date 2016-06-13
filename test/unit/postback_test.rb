# encoding: UTF-8
require_relative '../test_helper'

class PostbackTest < Minitest::Test

  def setup
    Postback.delete_all
  end

  def hpb(event, platform, user_id, network = nil, url_template = nil)
    { :network  => network,
      :event    => event,
      :user_id  => user_id,
      :platform => platform,
      :url_template => url_template
    }
  end

  def values_for(cache, network, event, user_id, platform)
    cache[network][event][user_id][platform].
      map(&:url_template).map(&:to_i).sort
  end

  context "cache for conversion event" do
    should "create one and support cache mis-hits" do
      [
       hpb("ist", "all",     1, "fubar", "1"),
       hpb("ist", "all",     1, "snafu", "2"),
       hpb("ist", "ios",     1, "fubar", "3"),
       hpb("ist", "ios",     1, "fubar", "4"),
       hpb("ist", "ios",     1, "snafu", "5"),
       hpb("mac", "all",     2, "fubar", "6"),
       hpb("mac", "all",     2, "fubar", "7"),
       hpb("mac", "all",     2, "snafu", "8"),
       hpb("apo", "ios",     2, "fubar", "9"),
       hpb("apo", "ios",     3, "snafu", "10"),
       hpb("apo", "all",     3, "fubar", "11"),
       hpb("fun", "android", 4, "fubar", "12"),
       hpb("fun", "android", 4, "snafu", "13"),
       hpb("fun", "android", 4, "fubar", "14"),
       hpb("ist", "ios",     1, "fubar", "15"),
      ].each { |data| generate_postback(data) }

      cache = Postback.cache_for_conversion_event

      assert_equal [1],      values_for(cache, "fubar", "ist", 1,"all")
      assert_equal [2],      values_for(cache, "snafu", "ist", 1,"all")
      assert_equal [3,4,15], values_for(cache, "fubar", "ist", 1,"ios")
      assert_equal [5],      values_for(cache, "snafu", "ist", 1,"ios")
      assert_equal [],       values_for(cache, "fubar", "mac", 1,"all")
      assert_equal [6,7],    values_for(cache, "fubar", "mac", 2,"all")
      assert_equal [8],      values_for(cache, "snafu", "mac", 2,"all")
      assert_equal [9],      values_for(cache, "fubar", "apo", 2,"ios")
      assert_equal [],       values_for(cache, "fubar", "apo", 2,"all")
      assert_equal [],       values_for(cache, "unkonwn", "apo", 2,"all")
      assert_equal [10],     values_for(cache, "snafu", "apo", 3,"ios")
      assert_equal [11],     values_for(cache, "fubar", "apo", 3,"all")
      assert_equal [12,14],  values_for(cache, "fubar", "fun", 4,"android")
      assert_equal [13],     values_for(cache, "snafu", "fun", 4,"android")
    end
  end

  context "cache for postback event" do
    should "create one" do
      [
       hpb("ist", "all",     1),
       hpb("ist", "ios",     2),
       hpb("ist", "ios",     3),
       hpb("mac", "all",     4),
       hpb("mac", "all",     5),
       hpb("apo", "ios",     6),
       hpb("apo", "all",     7),
       hpb("fun", "android", 8),
      ].each { |data| generate_postback(data) }

      cache = Postback.cache_for_postback_event

      assert_equal [1],   cache["ist"]["all"].map(&:user_id).sort
      assert_equal [2,3], cache["ist"]["ios"].map(&:user_id).sort
      assert_equal [4,5], cache["mac"]["all"].map(&:user_id).sort
      assert_equal [7],   cache["apo"]["all"].map(&:user_id).sort
      assert_equal [8],   cache["fun"]["android"].map(&:user_id).sort
      assert_equal [],    cache["mac"]["android"].map(&:user_id).sort
    end
  end
end
