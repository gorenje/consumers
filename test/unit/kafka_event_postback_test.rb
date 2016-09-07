# encoding: UTF-8
require_relative '../test_helper'
require_relative '../adnetwork_definitions'

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
    should "generate urls ignoring the user_id" do
      base_data = {
        :network       => "ist_network",
        :user_id       => 23,
        :event         => @event.call,
        :env           => {
          "netcfg" => {
            "sdk_key"      => "SdkKeyDemo",
            "package_name" => "PackageNameDemo",
          }
        }
      }

      postbacks = [
             { :platform     => "all",
               :user_id      => base_data[:user_id] + 1
             }
            ].map do |overrides|
        generate_postback(base_data.merge(overrides))
      end
      pb1 = postbacks.first

      assert_equal 1, @event.postbacks.count
      assert_equal([{:url=>"http://localhost.com/pix?brand=Apple&"+
                      "device_ip=3160894398&event=landing&idfa="+
                      "ECC27E57-1605-2714-CAFE-13DC6DFB742F&model="+
                      "fubar&package_name=PackageNameDemo&platform="+
                      "all&sdk_key=SdkKeyDemo",
                      :body=>"", :header=>{}, :pbid => pb1.id },
                   ],
                   @event.generate_urls.sort_by{ |h| h[:url] })
    end

    should "generate including all platforms" do
      base_data = {
        :network       => "ist_network",
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
                     },
                     { :platform     => @event.platform,
                     },
                     { :platform     => @event.platform,
                       :user_id      => base_data[:user_id] + 1
                     }
                    ].map do |overrides|
        generate_postback(base_data.merge(overrides))
      end

      assert_equal 3, @event.postbacks.count
      assert_equal([{:url=>"http://localhost.com/pix?brand=Apple&"+
                      "device_ip=3160894398&event=landing&idfa="+
                      "ECC27E57-1605-2714-CAFE-13DC6DFB742F&model=fubar"+
                      "&package_name=PackageNameDemo&platform=all&"+
                      "sdk_key=SdkKeyDemo",
                      :body=>"", :header=>{}, :pbid => pb1.id },
                    {:url=>"http://localhost.com/pix?brand=Apple&"+
                      "device_ip=3160894398&event=landing&idfa="+
                      "ECC27E57-1605-2714-CAFE-13DC6DFB742F&model=fubar&"+
                      "package_name=PackageNameDemo&platform=ios&"+
                      "sdk_key=SdkKeyDemo",
                      :body=>"", :header=>{}, :pbid => pb2.id},
                    {:url=>"http://localhost.com/pix?brand=Apple&"+
                      "device_ip=3160894398&event=landing&idfa="+
                      "ECC27E57-1605-2714-CAFE-13DC6DFB742F&model=fubar&"+
                      "package_name=PackageNameDemo&platform=ios&"+
                      "sdk_key=SdkKeyDemo",
                      :body=>"", :header=>{}, :pbid => pb3.id}],
                   @event.generate_urls.sort_by{ |h| h[:pbid] })
    end

    should "generate if user there" do
      base_data = {
        :network       => "usr_req_network",
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
                     },
                     { :platform     => @event.platform,
                     },
                     { :platform     => @event.platform,
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
      assert_equal([{:url=>"http://localhost.com/pix?brand=Apple&"+
                      "click=fubar&device_ip=3160894398&event=landing&"+
                      "idfa=ECC27E57-1605-2714-CAFE-13DC6DFB742F&"+
                      "model=fubar&package_name=PackageNameDemo&"+
                      "platform=all&sdk_key=SdkKeyDemo",
                      :body=>"", :header=>{}, :pbid => pb1.id},
                    {:url=>"http://localhost.com/pix?brand=Apple&"+
                      "click=fubar&device_ip=3160894398&event=landing&"+
                      "idfa=ECC27E57-1605-2714-CAFE-13DC6DFB742F&"+
                      "model=fubar&package_name=PackageNameDemo&"+
                      "platform=ios&sdk_key=SdkKeyDemo",
                      :body=>"", :header=>{}, :pbid => pb2.id}],
                   @event.generate_urls.sort_by{ |h| h[:pbid] })
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
