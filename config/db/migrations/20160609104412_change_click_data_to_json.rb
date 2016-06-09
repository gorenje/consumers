class ChangeClickDataToJson < ActiveRecord::Migration
  def up
    remove_column :network_users, :click_data
    add_column :network_users, :click_data, :json
  end

  def down
    remove_column :network_users, :click_data
    add_column :network_users, :click_data, :hstore
  end
end
