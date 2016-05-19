require 'digest/sha2'
require 'json'

# https://answers.chartboost.com/hc/en-us/articles/201220265#s2s
class Chartboost

  def self.signature(event, app_id, token)
    Digest::SHA2.hexdigest("action:pia;app:#{app_id};token:#{token};"+
                           "timestamp:#{event.trigger_stamp};")
  end

  def self.install_signature(event, api_secret, app_id, token)
    hsh_string = ["action:attribution",
                  "#{api_secret}",
                  "#{Chartboost.signature(event, app_id, token)}",
                  "#{Chartboost.install_body(event, app_id)}"].join("\n")
    Digest::SHA2.hexdigest hsh_string
  end

  def self.install_body(event, app_id)
    params = if event.android?
      { :gaid => event.gadid,
        :uuid => event.android_id || event.gadid
      }.select {|_,v| v.present?}
    else
      {:ifa => event.adid}
    end

    JSON.generate(params.merge({
      :app_id => app_id,
      :claim  => 1
    }))
  end

  def self.iap_body(event, token)
    JSON.generate({
      :platform       => :ios,
      :sdk_version    => 4.2,
      :token          => token,
      :identifiers    => {
        :ifa          => event.adid,
      },
      :receipt_valid  => false,
      :timestamp      => event.trigger_stamp,
      :iap            => {
        :currency   => event.currency,
        :price      => event.params[:price].to_f,
        :product_id => event.params[:st1] || event.params[:s1] || 'unknown'
      }
    })
  end
end
