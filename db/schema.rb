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

ActiveRecord::Schema.define(version: 2023_09_07_111739) do

  create_table "guest_users", force: :cascade do |t|
    t.string "guest_uid", null: false
    t.string "guest_name"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["guest_uid"], name: "index_guest_users_on_guest_uid", unique: true
  end

  create_table "line_groups", force: :cascade do |t|
    t.string "line_group_id"
    t.string "line_group_name"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "status"
  end

  create_table "line_groups_guest_users", force: :cascade do |t|
    t.integer "line_group_id", null: false
    t.integer "guest_user_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["guest_user_id"], name: "index_line_groups_guest_users_on_guest_user_id"
    t.index ["line_group_id"], name: "index_line_groups_guest_users_on_line_group_id"
  end

  create_table "line_groups_users", id: false, force: :cascade do |t|
    t.integer "line_group_id", null: false
    t.integer "user_id", null: false
  end

  create_table "schedules", force: :cascade do |t|
    t.string "title", null: false
    t.datetime "start_time"
    t.datetime "end_time"
    t.string "location"
    t.string "description"
    t.string "representative", null: false
    t.datetime "deadline", null: false
    t.string "user_id"
    t.string "line_group_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "status"
    t.string "url_token"
    t.string "leadership_award"
  end

  create_table "temp_schedules", force: :cascade do |t|
    t.string "title"
    t.datetime "start_time"
    t.string "representative"
    t.datetime "deadline"
    t.string "line_group_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "status", default: 0
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "provider"
    t.string "uid"
    t.string "name", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "line_groups_guest_users", "guest_users"
  add_foreign_key "line_groups_guest_users", "line_groups"
end
