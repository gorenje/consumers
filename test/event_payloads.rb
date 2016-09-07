class EventPayloads
  class << self
    def conversion
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
        "bb0ca0283abd536a7ae2941c6cde29dd%26network%3Dmac_network%26"+
        "partner_data%26redirect_url%3Dhttps%253A%252F%252Fplay.google.com"+
        "%252Fstore%252Fapps%252Fdetails%253Fid%253Dcom.fubar.game"+
        "%26user_id%3D2&install=%2Ft%2Fist%20bot_name%26country%3DUS"+
        "%26device%26device_name%26ip%3D1796505292%26klag%3D1%26platform"+
        "%3Dios%26ts%3D1465035505%20adid%3DECC27E57-1605-2714-CAFE-13DC6DFB742F"
    end

    def install
      "/t/ist bot_name&country=DE&device=smartphone&device_name="+
        "iPhone&ip=3160894398&klag=1&platform=ios&ts=1464712617 "+
        "adid=ECC27E57-1605-2714-CAFE-13DC6DFB742F&device=fubar"
    end

    def postback
      "/t/pob bot_name&country=DE&device=smartphone&device_name="+
        "iPhone&ip=3160894398&klag=1&platform=ios&ts=1464712617 "+
        "rc=200&s=ok&pbid=312&req={}"
    end

    def click
      "/t/click bot_name&country=DE&device=desktop&device_name&"+
        "ip=2986884497&klag=1&platform=mac&ts=1465468519 ad=&adgroup=&adid&"+
        "attr_window_from=2016-06-09T10%3A35%3A19%2B00%3A00&"+
        "attr_window_till=2016-06-10T10%3A35%3A19%2B00%3A00&campaign=fubsada&"+
        "campaign_link_id=46&click=click&created_at=2016-06-09T10%3A35%3A19"+
        "%2B00%3A00&idfa_comb&lookup_key=1c0cdbd7358cf020ecbb9fd8d19972cf&"+
        "network=7games&partner_data=fubar&redirect_url=https%3A%2F%2F"+
        "play.google.com%2Fstore%2Fapps%2Fdetails%3Fid%3Dadsad&"+
        "reqparams=andmore%3Ddata%26someother%3Ddata&user_id=1"
    end
  end
end
