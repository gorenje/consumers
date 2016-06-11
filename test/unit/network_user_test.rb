# encoding: UTF-8
require_relative '../test_helper'

class NetworkUserTest < Minitest::Test

  context "click_data" do
    should "have working wrapper class" do
      nc = NetworkUser.create( :data => {
                                 "partner_data" => nil,
                                 "campaign"     => "fubsada",
                                 "andmore"      => ["data"],
                                 "someother"    => ["data", "two", "values"]})
      nc = NetworkUser.find(nc.id) # reload

      assert_nil nc.click_data[:partner_data]
      assert_nil nc.click_data["partner_data"]
      assert_nil nc.click_data.partner_data

      assert_equal "fubsada", nc.click_data[:campaign]
      assert_equal "fubsada", nc.click_data["campaign"]
      assert_equal "fubsada", nc.click_data.campaign

      assert_equal "data", nc.click_data[:andmore]
      assert_equal "data", nc.click_data["andmore"]
      assert_equal "data", nc.click_data.andmore

      assert_equal ["data", "two", "values"], nc.click_data[:someother]
      assert_equal ["data", "two", "values"], nc.click_data["someother"]
      assert_equal ["data", "two", "values"], nc.click_data.someother
    end
  end
end
