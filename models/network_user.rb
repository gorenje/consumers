class NetworkUser < ActiveRecord::Base

  class WrapClickData
    # This does three things:
    #  - allow for direct access to variables using methods
    #  - remove arrays if they contain a single value (this comes from
    #    the request_params hash)
    #  - provide indifferent access, i.e. symbol or string will work.
    def initialize(data)
      @data = data
    end

    def method_missing(name, *args, &block)
      v = @data[name] || @data[name.to_s]
      (v.is_a?(Array) && v.size == 1) ? v.first : v
    end

    def [](name)
      send(name)
    end
  end

  def self.create_new_for_conversion(click, install, postback)
    return unless click.adid.present? || install.adid.present?

    create(:user_identifier => click.adid || install.adid,
           :network         => click.network,
           :user_id         => postback.user_id,
           :data            => click.click_data_for_network_user)
  end

  def click_data
    @cd ||= WrapClickData.new(data)
  end
end
