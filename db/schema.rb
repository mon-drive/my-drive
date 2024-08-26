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

ActiveRecord::Schema.define(version: 2024_08_26_090911) do

  create_table "contains", force: :cascade do |t|
    t.integer "user_folder_id"
    t.integer "user_file_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["user_file_id"], name: "index_contains_on_user_file_id"
    t.index ["user_folder_id"], name: "index_contains_on_user_folder_id"
  end

  create_table "converts", force: :cascade do |t|
    t.integer "user_file_id"
    t.integer "premium_user_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["premium_user_id"], name: "index_converts_on_premium_user_id"
    t.index ["user_file_id"], name: "index_converts_on_user_file_id"
  end

  create_table "has_owners", force: :cascade do |t|
    t.integer "owner_id"
    t.string "item"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["owner_id"], name: "index_has_owners_on_owner_id"
  end

  create_table "has_parents", force: :cascade do |t|
    t.integer "parent_id"
    t.string "item_type", null: false
    t.integer "item_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["item_type", "item_id"], name: "index_has_parents_on_item"
    t.index ["parent_id"], name: "index_has_parents_on_parent_id"
  end

  create_table "has_permissions", force: :cascade do |t|
    t.string "item_type"
    t.string "item_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "permission_id"
    t.index ["item_type", "item_id"], name: "index_has_permissions_on_item"
  end

  create_table "makes", force: :cascade do |t|
    t.integer "user_id"
    t.integer "transaction_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["transaction_id"], name: "index_makes_on_transaction_id"
    t.index ["user_id"], name: "index_makes_on_user_id"
  end

  create_table "owners", force: :cascade do |t|
    t.string "displayName"
    t.string "emailAddress"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "parents", force: :cascade do |t|
    t.string "itemid"
    t.integer "num"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "permissions", force: :cascade do |t|
    t.string "permission_type"
    t.string "role"
    t.string "emailAddress"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "permission_id"
    t.index ["permission_id"], name: "index_permissions_on_permission_id"
  end

  create_table "possesses", force: :cascade do |t|
    t.integer "user_id"
    t.integer "user_folder_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["user_folder_id"], name: "index_possesses_on_user_folder_id"
    t.index ["user_id"], name: "index_possesses_on_user_id"
  end

  create_table "share_files", force: :cascade do |t|
    t.integer "user_id"
    t.integer "user_file_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["user_file_id"], name: "index_share_files_on_user_file_id"
    t.index ["user_id"], name: "index_share_files_on_user_id"
  end

  create_table "share_folders", force: :cascade do |t|
    t.integer "user_id"
    t.integer "user_folder_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["user_folder_id"], name: "index_share_folders_on_user_folder_id"
    t.index ["user_id"], name: "index_share_folders_on_user_id"
  end

  create_table "transactions", force: :cascade do |t|
    t.datetime "data"
    t.string "transaction_type"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "user_files", force: :cascade do |t|
    t.string "user_file_id"
    t.string "name"
    t.string "mime_type"
    t.integer "size"
    t.datetime "created_time"
    t.datetime "modified_time"
    t.boolean "shared"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "web_view_link"
    t.string "icon_link"
    t.string "file_extension"
    t.boolean "trashed", default: false
    t.index ["user_file_id"], name: "index_user_files_on_user_file_id", unique: true
  end

  create_table "user_folders", force: :cascade do |t|
    t.string "user_folder_id"
    t.string "name"
    t.string "mime_type"
    t.integer "size"
    t.datetime "created_time"
    t.datetime "modified_time"
    t.boolean "shared"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.boolean "trashed", default: false
    t.index ["user_folder_id"], name: "index_user_folders_on_user_folder_id", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "username"
    t.string "type"
    t.string "email"
    t.string "profile_picture"
    t.date "expire_date"
    t.string "provider"
    t.string "uid"
    t.string "oauth_token"
    t.string "refresh_token"
    t.datetime "oauth_expires_at"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  add_foreign_key "contains", "user_files"
  add_foreign_key "contains", "user_files"
  add_foreign_key "contains", "user_folders"
  add_foreign_key "converts", "user_files"
  add_foreign_key "converts", "user_files"
  add_foreign_key "converts", "users", column: "premium_user_id"
  add_foreign_key "has_owners", "owners"
  add_foreign_key "has_parents", "parents"
  add_foreign_key "has_permissions", "permissions"
  add_foreign_key "makes", "transactions"
  add_foreign_key "makes", "users"
  add_foreign_key "possesses", "user_folders"
  add_foreign_key "possesses", "users"
  add_foreign_key "share_files", "user_files"
  add_foreign_key "share_files", "user_files"
  add_foreign_key "share_files", "users"
  add_foreign_key "share_folders", "user_folders"
  add_foreign_key "share_folders", "users"
end
