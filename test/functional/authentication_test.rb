# encoding: UTF-8
require_relative '../test_helper'

class AuthenticaionTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Rack::Builder.parse_file('config.ru').first
  end

  context "authentication" do
    should "prevent access" do
      ["/sidekiq", '/badclicks', '/badclicks/clear_all', '/'
       ].each do |path|
        get path
        assert_redirect_to("auth", "Failed for #{path}")
      end
    end

    should "allow access - get" do
      ["/pingdom", "/accessdenied"].
        each do |path|
        get path
        assert last_response.ok?, "Failed for #{path}"
      end
    end

    should "allow access to api" do
      replace_in_env("API_SECRET_KEY" => nil) do
        post "/api/1/create", {:postback => { "id" => 1}.to_json}
        assert last_response.ok?

        get "/api/1/create", {:postback => { "id" => 1}.to_json}
        assert last_response.not_found?
      end
    end

    should "redirect to google" do
      get "/auth"

      assert(last_response.headers["Location"] =~ /https:\/\/accounts.google.com\/o\/oauth2\/auth\?access_type=offline/)
    end
  end
end
