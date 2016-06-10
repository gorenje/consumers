# encoding: UTF-8
require_relative '../test_helper'

class KafkaConversionEventTest < Minitest::Test

  def setup
    payload =
      "/t/mac bot_name&country=US&device&device_name&ip=1796505292&klag=0&"+
      "platform=&ts=1465035508 click=%2Ft%2Fclick%20bot_name%26country%3DUS"+
      "%26device%26device_name%26ip%3D1796505292%26klag%3D0%26platform%3D"+
      "%26ts%3D1465035501%20ad%3Dad%26adgroup%3Dadtroup%26adid%3D"+
      "ECC27E57-1605-2714-CAFE-13DC6DFB742F%26attr_window_from"+
      "%3D2016-06-04T10%253A18%253A21%252B00%253A00%26attr_window_till"+
      "%3D2016-06-07T05%253A30%253A21%252B00%253A00%26campaign%3Dfubar"+
      "%26campaign_link_id%3D41%26click%3Dclickdata%26created_at%3D"+
      "2016-06-04T10%253A18%253A21%252B00%253A00%26idfa_comb%3D"+
      "ECC27E57-1605-2714-CAFE-13DC6DFB742F%26lookup_key%3D"+
      "bb0ca0283abd536a7ae2941c6cde29dd%26network%3Deccrine%26"+
      "partner_data%26redirect_url%3Dhttps%253A%252F%252Fplay.google.com"+
      "%252Fstore%252Fapps%252Fdetails%253Fid%253Dcom.fubar.game"+
      "%26user_id%3D2&install=%2Ft%2Fist%20bot_name%26country%3DUS"+
      "%26device%26device_name%26ip%3D1796505292%26klag%3D1%26platform"+
      "%3D%26ts%3D1465035505%20adid%3DECC27E57-1605-2714-CAFE-13DC6DFB742F"
    @event = Consumers::Kafka::ConversionEvent.new(payload)
    NetworkUser.delete_all
    Postback.delete_all
  end

  context "basics" do
    should "have click and install events" do
      assert_kind_of Consumers::Kafka::InstallEvent, @event.install
      assert_kind_of Consumers::Kafka::ClickEvent, @event.click
    end

    should "have idfas" do
      assert_equal "ECC27E57-1605-2714-CAFE-13DC6DFB742F", @event.install.idfa
      assert_equal @event.install.idfa, @event.click.idfa
      assert_equal @event.idfa, @event.click.idfa
    end

    should "generate urls" do
      url = "https://localhost.com/conv?adid=@{event.adid}@&aid="+
        "@{netcfg.aid}@&did=@{params[:click]}@&pkg=@{netcfg.pkg}@"

      base_data = {
        :network => @event.network,
        :event   => @event.call,
        :user_id => @event.user_id,
        :env     => {
          "netcfg" => {
            "aid" => "AidDemo",
            "pkg" => "PackageNameDemo",
          }
        }
      }

      [
       # don't select this since the platform doesn't match
       { :platform      => @event.platform + "dontselect",
         :url_template  => url + "&false=1",
       },
       # select this since the platform is 'all'
       { :platform      => "all",
         :url_template  => url,
       },
       # select this since the platform is the same as the event
       { :platform      => @event.platform,
         :url_template  => url + "&true=1",
       },
       # don't use this because it requires a user.
       { :platform      => "all",
         :url_template  => url + "&false=f",
         :user_required => true
       }
      ].each { |overrides| generate_postback(overrides.merge(base_data)) }

      assert_equal 2, @event.generate_urls.count
      assert_equal([{:url=>"https://localhost.com/conv?adid="+
                      "ECC27E57-1605-2714-CAFE-13DC6DFB742F&aid=AidDemo&"+
                      "did=clickdata&pkg=PackageNameDemo",
                      :body=>nil, :header=>{}},
                      {:url=>"https://localhost.com/conv?adid="+
                        "ECC27E57-1605-2714-CAFE-13DC6DFB742F&aid=AidDemo&"+
                        "did=clickdata&pkg=PackageNameDemo&true=1",
                     :body=>nil, :header=>{}}],
                   @event.generate_urls.sort_by { |h| h[:url] })
    end
  end
end
