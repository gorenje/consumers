class CreatePostbacks < ActiveRecord::Migration
  def change
    create_table :postbacks do |t|
      t.string  :network
      t.string  :event
      t.string  :platform
      t.integer :user_id

      t.boolean :user_required, :default => false
      t.boolean :store_user, :default => false

      t.json    :env
      t.string  :url_template, :length => 1024
    end

    add_index "postbacks", ["network", "event", "platform"]
  end
end
