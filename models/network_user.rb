class NetworkUser < ActiveRecord::Base

  def self.create_new_from_click_and_install(click, install)
    return unless click.adid.present? || install.adid.present?

    NetworkUser.create(:user_identifier => click.adid || install.adid,
                       :network         => click.network,
                       :click_data      => click.params)
  end
end
