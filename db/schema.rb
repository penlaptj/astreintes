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

ActiveRecord::Schema[8.1].define(version: 2026_06_09_000000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "noticed_events", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "notifications_count"
    t.jsonb "params"
    t.bigint "record_id"
    t.string "record_type"
    t.string "type"
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id"], name: "index_noticed_events_on_record"
  end

  create_table "noticed_notifications", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "event_id", null: false
    t.datetime "read_at", precision: nil
    t.bigint "recipient_id", null: false
    t.string "recipient_type", null: false
    t.datetime "seen_at", precision: nil
    t.string "type"
    t.datetime "updated_at", null: false
    t.index ["event_id"], name: "index_noticed_notifications_on_event_id"
    t.index ["recipient_type", "recipient_id"], name: "index_noticed_notifications_on_recipient"
  end

  create_table "notifications", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.jsonb "data"
    t.string "notification_type"
    t.boolean "read"
    t.bigint "receiver_id", null: false
    t.integer "sender_id"
    t.bigint "slot_id", null: false
    t.datetime "updated_at", null: false
    t.index ["receiver_id"], name: "index_notifications_on_receiver_id"
    t.index ["slot_id"], name: "index_notifications_on_slot_id"
  end

  create_table "services", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "description"
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_services_on_name", unique: true
  end

  create_table "slots", force: :cascade do |t|
    t.string "assignment_state", default: "available", null: false
    t.decimal "compensation_days", precision: 5, scale: 1
    t.decimal "compensation_money", precision: 10, scale: 2
    t.datetime "created_at", null: false
    t.string "description"
    t.datetime "ends_at"
    t.bigint "requested_by_id"
    t.bigint "service_id"
    t.string "slot_type"
    t.datetime "starts_at"
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["requested_by_id"], name: "index_slots_on_requested_by_id"
    t.index ["service_id"], name: "index_slots_on_service_id"
    t.index ["user_id"], name: "index_slots_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.boolean "active"
    t.datetime "created_at", null: false
    t.string "discord_user_id"
    t.string "email"
    t.string "first_name"
    t.string "last_name"
    t.string "notification_channels", default: ["slack"], null: false, array: true
    t.string "notification_periods", default: ["slots"], null: false, array: true
    t.string "password_digest"
    t.string "role"
    t.bigint "service_id"
    t.string "slack_uid"
    t.string "telegram_chat_id"
    t.string "theme", default: "default", null: false
    t.datetime "updated_at", null: false
    t.index ["service_id"], name: "index_users_on_service_id"
  end

  add_foreign_key "notifications", "slots"
  add_foreign_key "notifications", "users", column: "receiver_id"
  add_foreign_key "notifications", "users", column: "sender_id"
  add_foreign_key "slots", "services"
  add_foreign_key "slots", "users"
  add_foreign_key "slots", "users", column: "requested_by_id"
  add_foreign_key "users", "services"
end
