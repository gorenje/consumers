class UpdateIndiciesForPostback < ActiveRecord::Migration
  def up
    remove_index "postbacks", ["network", "event", "platform"]
    add_index "postbacks", ["network", "event", "user_id", "platform"]
    add_index "postbacks", ["event", "platform"]
  end

  def down
    add_index "postbacks", ["network", "event", "platform"]
    remove_index "postbacks", ["network", "event", "user_id", "platform"]
    remove_index "postbacks", ["event", "platform"]
  end
end
