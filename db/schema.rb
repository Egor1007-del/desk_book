# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_10_02_005823) do
  create_table "positions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_positions_on_name", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email"
    t.string "encrypted_password", null: false
    t.string "first_name", null: false
    t.date "hired_on", null: false
    t.string "last_name", null: false
    t.string "login", null: false
    t.string "middle_name"
    t.string "phone"
    t.integer "position_id", null: false
    t.datetime "updated_at", null: false
    t.index "LOWER(login)", name: "index_users_on_lower_login", unique: true
    t.index ["position_id"], name: "index_users_on_position_id"
  end

  add_foreign_key "users", "positions"
end
