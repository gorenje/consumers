# encoding: UTF-8
require_relative '../test_helper'

class ApiTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Rack::Builder.parse_file('config.ru').first
  end

  def setup
  end

  context "delete" do
    should "delete postback" do
      replace_in_env("API_SECRET_KEY" => "somekey") do
        pb = generate_postback
        Postback.delete_all
        salt = "somesalt"
        pepper = Digest::SHA1.hexdigest(salt + pb.to_json + "somekey")
        assert 1, Postback.count

        post("/api/1/delete", { :postback => pb.to_json, :pepper => pepper },
             { "HTTP_X_API_SALT" => salt })

        assert_raises ActiveRecord::RecordNotFound do
          Postback.find(pb.id)
        end
        assert_zero Postback.count
        assert last_response.ok?
      end
    end

    should "not do anything if pepper is wrong" do
      replace_in_env("API_SECRET_KEY" => "somekey") do
        Postback.delete_all
        pb = generate_postback
        salt = "somesalt"
        pepper = Digest::SHA1.hexdigest(salt + pb.to_json + "somekey")

        post("/api/1/delete", {:postback => pb.to_json, :pepper => pepper }, {})

        assert_one Postback.count
        assert last_response.not_found?
      end
    end
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

    should "update existing postback" do
      replace_in_env("API_SECRET_KEY" => nil) do
        pb = generate_postback(:network => "snafu")
        Postback.delete_all
        post("/api/1/create", { :postback => pb.to_json })
        assert_one Postback.count

        pb = Postback.find(pb.id)
        assert_equal "snafu", pb.network
        pb.network = "fubar"

        post("/api/1/create", { :postback => pb.to_json })
        assert_one Postback.count
        assert last_response.ok?

        pb = Postback.find(pb.id)
        assert_equal "fubar", pb.network
      end
    end
  end

  context "with api key" do
    should "respond with 404 if no salt" do
      replace_in_env("API_SECRET_KEY" => "somekey") do
        pb = generate_postback
        Postback.delete_all
        salt = "somesalt"
        pepper = Digest::SHA1.hexdigest(salt + pb.to_json + "somekey")

        post("/api/1/create", { :postback => pb.to_json, :pepper => pepper },
             {})

        assert_zero Postback.count
        assert last_response.not_found?
      end
    end

    should "respond with 404 if no match using pepper" do
      replace_in_env("API_SECRET_KEY" => "somekey") do
        pb = generate_postback
        Postback.delete_all
        salt = "somesalt"
        pepper = Digest::SHA1.hexdigest(salt + pb.to_json + "somekey")

        post("/api/1/create", { :postback => pb.to_json, :pepper => "p" },
             { "HTTP_X_API_SALT" => salt })

        assert_zero Postback.count
        assert last_response.not_found?
      end
    end

    should "work but ignore the key if none is set" do
      replace_in_env("API_SECRET_KEY" => nil) do
        pb = generate_postback
        Postback.delete_all
        salt = "somesalt"
        pepper = Digest::SHA1.hexdigest(salt + pb.to_json + "somekey")

        post("/api/1/create", { :postback => pb.to_json, :pepper => pepper },
             { "HTTP_X_API_SALT" => salt })

        assert Postback.find(pb.id)
        assert_one Postback.count
        assert last_response.ok?
      end
    end

    should "create new postback" do
      replace_in_env("API_SECRET_KEY" => "somekey") do
        pb = generate_postback
        Postback.delete_all
        salt = "somesalt"
        pepper = Digest::SHA1.hexdigest(salt + pb.to_json + "somekey")

        post("/api/1/create", { :postback => pb.to_json, :pepper => pepper },
             { "HTTP_X_API_SALT" => salt })

        assert Postback.find(pb.id)
        assert_one Postback.count
        assert last_response.ok?
      end
    end

    should "not work if pepper not sent" do
      replace_in_env("API_SECRET_KEY" => "somekey") do
        pb = generate_postback
        Postback.delete_all
        post("/api/1/create", { :postback => pb.to_json })

        assert_zero Postback.count
        assert last_response.not_found?
      end
    end
  end
end
