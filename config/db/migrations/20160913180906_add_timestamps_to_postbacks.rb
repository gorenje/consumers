class AddTimestampsToPostbacks < ActiveRecord::Migration
  def change
    [:postbacks].each do |tname|
      change_table tname do |t|
        t.timestamps
      end
    end
  end
end
