# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20160512081935) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "hstore"

  create_table "network_users", force: :cascade do |t|
    t.string   "user_identifier", limit: 64
    t.string   "network",         limit: 512
    t.integer  "user_id"
    t.hstore   "click_data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "network_users", ["user_identifier", "user_id", "network"], name: "index_network_users_on_user_identifier_and_user_id_and_network", using: :btree
  add_index "network_users", ["user_identifier", "user_id"], name: "index_network_users_on_user_identifier_and_user_id", using: :btree
  add_index "network_users", ["user_identifier"], name: "index_network_users_on_user_identifier", using: :btree

  create_table "postbacks", force: :cascade do |t|
    t.string  "network"
    t.string  "event"
    t.string  "platform"
    t.integer "user_id"
    t.boolean "user_required", default: false
    t.boolean "store_user",    default: false
    t.json    "env"
    t.string  "url_template"
  end

  add_index "postbacks", ["network", "event", "platform"], name: "index_postbacks_on_network_and_event_and_platform", using: :btree

end
