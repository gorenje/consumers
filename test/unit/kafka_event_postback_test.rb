# encoding: UTF-8
require_relative '../test_helper'

class KafkaEventPostbackTest < Minitest::Test

  def setup
    @payload = EventPayloads.install
    @event = Consumers::Kafka::PostbackEvent.new(@payload)
    NetworkUser.delete_all
    Postback.delete_all
  end

  context "cache" do
    should "use it correctly" do
      c = {
        "ist" => {
          "ios" => [1,2,3,4],
          "all" => [5,6,7,8]
        }
      }
      assert_equal [1,2,3,4,5,6,7,8], @event.postbacks(c).sort
    end
  end

  context "generate urls" do
    should "generate if no user is required" do
      url = "http://localhost.com/pix?event=landing&package_name="+
        "@{netcfg.package_name}@&sdk_key=@{netcfg.sdk_key}@"+
        "&platform=ios&brand=Apple&model=@{params[:device]}@"+
        "&device_ip=@{event.ip}@&idfa=@{event.adid}@"

      base_data = {
        :network       => "network",
        :user_id       => 23,
        :event         => @event.call,
        :env           => {
          "netcfg" => {
            "sdk_key"      => "SdkKeyDemo",
            "package_name" => "PackageNameDemo",
          }
        }
      }

      pb1,pb2,pb3 = [
                     { :platform     => "all",
                       :url_template => url + "&plaform=all",
                     },
                     { :platform     => @event.platform,
                       :url_template => url
                     },
                     { :platform     => @event.platform,
                       :url_template => url + "&user_id_mismatch",
                       :user_id      => base_data[:user_id] + 1
                     }
                    ].map do |overrides|
        generate_postback(base_data.merge(overrides))
      end

      assert_equal 3, @event.postbacks.count
      assert_equal([{:url=>"http://localhost.com/pix?event=landing&"+
                      "package_name=PackageNameDemo&sdk_key=SdkKeyDemo&"+
                      "platform=ios&brand=Apple&model=fubar&device_ip="+
                      "3160894398&idfa=ECC27E57-1605-2714-CAFE-13DC6DFB742F",
                      :body=>nil, :header=>{}, :pbid => pb2.id },
                    {:url=>"http://localhost.com/pix?event=landing&"+
                      "package_name=PackageNameDemo&sdk_key=SdkKeyDemo&"+
                      "platform=ios&brand=Apple&model=fubar&device_ip="+
                      "3160894398&idfa=ECC27E57-1605-2714-CAFE-13DC6DFB742F"+
                      "&plaform=all", :body=>nil, :header=>{}, :pbid => pb1.id},
                    {:url=>"http://localhost.com/pix?event=landing&"+
                      "package_name=PackageNameDemo&sdk_key=SdkKeyDemo&"+
                      "platform=ios&brand=Apple&model=fubar&device_ip="+
                      "3160894398&idfa=ECC27E57-1605-2714-CAFE-13DC6DFB742F"+
                      "&user_id_mismatch", :body=>nil, :header=>{},
                      :pbid => pb3.id}],
                   @event.generate_urls.sort_by{ |h| h[:url] })
    end

    should "generate if user there" do
      url = "http://localhost.com/pix?event=landing&package_name="+
        "@{netcfg.package_name}@&sdk_key=@{netcfg.sdk_key}@"+
        "&platform=ios&brand=Apple&model=@{params[:device]}@"+
        "&device_ip=@{event.ip}@&idfa=@{event.adid}@&did="+
        "@{user.click_data['click']}@"

      base_data = {
        :network       => "network",
        :user_id       => 23,
        :event         => @event.call,
        :user_required => true,
        :env           => {
          "netcfg" => {
            "sdk_key"      => "SdkKeyDemo",
            "package_name" => "PackageNameDemo",
          }
        }
      }

      pb1,pb2,pb3 = [
                     { :platform     => "all",
                       :url_template => url + "&plaform=all",
                     },
                     { :platform     => @event.platform,
                       :url_template => url
                     },
                     { :platform     => @event.platform,
                       :url_template => url + "&user_id_mismatch",
                       :user_id      => base_data[:user_id] + 1
                     }
                    ].map do |overrides|
        generate_postback(base_data.merge(overrides))
      end

      NetworkUser.
        create(:network         => base_data[:network],
               :user_identifier => @event.adid,
               :user_id         => base_data[:user_id],
               :data            => { :click => "fubar" })

      assert_equal 3, @event.postbacks.count
      assert_equal([{:url=>"http://localhost.com/pix?event=landing&"+
                      "package_name=PackageNameDemo&sdk_key=SdkKeyDemo&"+
                      "platform=ios&brand=Apple&model=fubar&device_ip="+
                      "3160894398&idfa=ECC27E57-1605-2714-CAFE-13DC6DFB742F"+
                      "&did=fubar", :body=>nil, :header=>{}, :pbid => pb2.id},
                    {:url=>"http://localhost.com/pix?event=landing&"+
                      "package_name=PackageNameDemo&sdk_key=SdkKeyDemo&"+
                      "platform=ios&brand=Apple&model=fubar&device_ip="+
                      "3160894398&idfa=ECC27E57-1605-2714-CAFE-13DC6DFB742F"+
                      "&did=fubar&plaform=all", :body=>nil, :header=>{},
                      :pbid => pb1.id}],
                   @event.generate_urls.sort_by{ |h| h[:url] })
    end

    should "do nothing if user_required and none there" do
      base_data = {
        :network       => "network",
        :event         => @event.call,
        :user_id       => 23,
        :user_required => true,
      }

      [
       { :platform => @event.platform + "dontselect" },
       { :platform => "all" },
       { :platform => @event.platform },
       { :platform => "all" }
      ].each { |overrides| generate_postback(overrides.merge(base_data)) }

      assert_equal 3, @event.postbacks.count
      assert_equal [], @event.generate_urls
    end
  end
end
