class CreateNetworkUsers < ActiveRecord::Migration
  def change
    create_table :network_users do |t|
      t.string  :user_identifier, :limit => 64
      t.string  :network,         :limit => 512
      # this is actually the customer id, i.e. the customer that
      # caused this user to be store and to whom they belong.
      t.integer :user_id
      t.hstore  :click_data
      t.timestamps
    end

    add_index "network_users", ["user_identifier"]
    add_index "network_users", ["user_identifier", "user_id"]
    add_index "network_users", ["user_identifier", "user_id", "network"]
  end
end
