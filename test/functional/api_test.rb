# encoding: UTF-8
require_relative '../test_helper'

class ApiTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Rack::Builder.parse_file('config.ru').first
  end

  def setup
  end

  context "without api key" do
    should "create new postback" do
      replace_in_env("API_SECRET_KEY" => nil) do
        pb = generate_postback
        Postback.delete_all
        post("/api/1/create", { :postback => pb.to_json })

        assert Postback.find(pb.id)
        assert last_response.ok?
        assert_equal "ok", JSON.parse(last_response.body)["status"]
      end
    end
  end
end
