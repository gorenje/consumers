require 'adtekio_adnetworks'

module AdnetworkDefintions
  class Mynetwork < AdtekioAdnetworks::BasePostbackClass
    include AdtekioAdnetworks::BasePostbacks

    define_network_config do
      []
    end

    define_postback_for :all, :apo do
      { :url => "http://google.de",
        :params => {
          :app_id   => "@{params[:partner_data]}@",
          :click_id => "@{params[:click]}@"
        },
      }
    end
  end

  class InstallNetwork < AdtekioAdnetworks::BasePostbackClass
    include AdtekioAdnetworks::BasePostbacks

    define_network_config do
      [:sdk_key, :package_name]
    end

    define_postback_for :ios, :ist do
      { :url => "http://localhost.com/pix",
        :params => {
          :event        => "landing",
          :platform     => "ios",
          :brand        => "Apple",
          :package_name => "@{netcfg.package_name}@",
          :sdk_key      => "@{netcfg.sdk_key}@",
          :model        => "@{params[:device]}@",
          :device_ip    => "@{event.ip}@",
          :idfa         => "@{event.adid}@"
        },
      }
    end

    define_postback_for :all, :ist do
      { :url => "http://localhost.com/pix",
        :params => {
          :event        => "landing",
          :platform     => "all",
          :brand        => "Apple",
          :package_name => "@{netcfg.package_name}@",
          :sdk_key      => "@{netcfg.sdk_key}@",
          :model        => "@{params[:device]}@",
          :device_ip    => "@{event.ip}@",
          :idfa         => "@{event.adid}@"
        },
      }
    end
  end

  class InstallNetworkUserRequired < AdtekioAdnetworks::BasePostbackClass
    include AdtekioAdnetworks::BasePostbacks

    define_network_config do
      [:sdk_key, :package_name]
    end

    define_postback_for :ios, :ist do
      { :url => "http://localhost.com/pix",
        :params => {
          :event        => "landing",
          :platform     => "ios",
          :brand        => "Apple",
          :package_name => "@{netcfg.package_name}@",
          :sdk_key      => "@{netcfg.sdk_key}@",
          :model        => "@{params[:device]}@",
          :device_ip    => "@{event.ip}@",
          :idfa         => "@{event.adid}@",
          :click        => "@{user.click_data[:click]}@"
        },
        :user_required => true
      }
    end

    define_postback_for :all, :ist do
      { :url => "http://localhost.com/pix",
        :params => {
          :event        => "landing",
          :platform     => "all",
          :brand        => "Apple",
          :package_name => "@{netcfg.package_name}@",
          :sdk_key      => "@{netcfg.sdk_key}@",
          :model        => "@{params[:device]}@",
          :device_ip    => "@{event.ip}@",
          :idfa         => "@{event.adid}@",
          :click        => "@{user.click_data[:click]}@"
        },
        :user_required => true
      }
    end
  end

  class ConversionNetwork < AdtekioAdnetworks::BasePostbackClass
    include AdtekioAdnetworks::BasePostbacks

    define_network_config do
      [:sdk_key, :package_name]
    end

    define_postback_for :ios, :mac do
        { :url => "https://localhost.com/conv",
        :params => {
          :adid => "@{event.adid}@",
          :aid  => "@{netcfg.aid}@",
          :did  => "@{params[:click]}@",
          :pkg  => "@{netcfg.pkg}@"
        },
      }
    end

    define_postback_for :all, :mac do
        { :url => "https://localhost.com/convALL",
        :params => {
          :adid => "@{event.adid}@",
          :aid  => "@{netcfg.aid}@",
          :did  => "@{params[:click]}@",
          :pkg  => "@{netcfg.pkg}@"
        },
      }
    end
  end
end

{
  :mynetwork       => AdnetworkDefintions::Mynetwork,
  :ist_network     => AdnetworkDefintions::InstallNetwork,
  :usr_req_network => AdnetworkDefintions::InstallNetworkUserRequired,
  :mac_network     => AdnetworkDefintions::ConversionNetwork
}.each do |name, klz|
  AdtekioAdnetworks::Postbacks.networks[name] = klz
end
