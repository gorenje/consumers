require File.dirname(File.expand_path(__FILE__)) + '/../helper.rb'
require 'ostruct'

class TestEvents < Minitest::Test
  context "payment" do
    should "use the path" do
      obj = AdtekioTracking::Events.new
      mock(obj).send_request('/t/pay',{}) do
        "returnvalue"
      end
      assert_equal "returnvalue", obj.payment
    end
  end
end
