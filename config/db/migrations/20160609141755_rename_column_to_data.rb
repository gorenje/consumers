class RenameColumnToData < ActiveRecord::Migration
  def change
    rename_column :network_users, :click_data, :data
  end
end
