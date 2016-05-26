class NetworkUser < ActiveRecord::Base

  def self.create_new_for_conversion(click, install, postback)
    return unless click.adid.present? || install.adid.present?

    click_data = if postback.env["user_attributes"].is_a?(Array)
                   Hash[postback.env["user_attributes"].map do |attr|
                          [attr, click.params[attr.to_sym]]
                        end]
                 else
                   {}
                 end

    NetworkUser.create(:user_identifier => click.adid || install.adid,
                       :network         => click.network,
                       :user_id         => postback.user_id,
                       :click_data      => click_data)
  end
end
