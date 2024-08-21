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

ActiveRecord::Schema.define(version: 2024_08_21_140125) do

  create_table "contains", force: :cascade do |t|
    t.integer "folder_id"
    t.integer "file_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["file_id"], name: "index_contains_on_file_id"
    t.index ["folder_id"], name: "index_contains_on_folder_id"
  end

  create_table "converts", force: :cascade do |t|
    t.integer "file_id"
    t.integer "premium_user_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["file_id"], name: "index_converts_on_file_id"
    t.index ["premium_user_id"], name: "index_converts_on_premium_user_id"
  end

  create_table "files", force: :cascade do |t|
    t.string "file_id"
    t.string "name"
    t.string "mime_type"
    t.integer "size"
    t.datetime "created_time"
    t.datetime "modified_time"
    t.boolean "shared"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

# Could not dump table "folders" because of following StandardError
#   Unknown type '' for column 'owners'

  create_table "has_owners", force: :cascade do |t|
    t.integer "owner_id"
    t.string "item"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["owner_id"], name: "index_has_owners_on_owner_id"
  end

  create_table "has_parents", force: :cascade do |t|
    t.integer "parent_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "item_id", null: false
    t.string "item_type", null: false
    t.index ["parent_id"], name: "index_has_parents_on_parent_id"
  end

  create_table "has_permissions", force: :cascade do |t|
    t.integer "permission_id"
    t.string "item"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "item_id", null: false
    t.string "item_type", null: false
    t.index ["permission_id"], name: "index_has_permissions_on_permission_id"
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
    t.integer "folder_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["folder_id"], name: "index_possesses_on_folder_id"
    t.index ["user_id"], name: "index_possesses_on_user_id"
  end

  create_table "share_files", force: :cascade do |t|
    t.integer "user_id"
    t.integer "file_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["file_id"], name: "index_share_files_on_file_id"
    t.index ["user_id"], name: "index_share_files_on_user_id"
  end

  create_table "share_folders", force: :cascade do |t|
    t.integer "user_id"
    t.integer "folder_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["folder_id"], name: "index_share_folders_on_folder_id"
    t.index ["user_id"], name: "index_share_folders_on_user_id"
  end

  create_table "transactions", force: :cascade do |t|
    t.datetime "data"
    t.string "transaction_type"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
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

  add_foreign_key "contains", "files"
  add_foreign_key "contains", "folders"
  add_foreign_key "converts", "files"
  add_foreign_key "converts", "users", column: "premium_user_id"
  add_foreign_key "has_owners", "owners"
  add_foreign_key "has_parents", "parents"
  add_foreign_key "has_permissions", "permissions"
  add_foreign_key "makes", "transactions"
  add_foreign_key "makes", "users"
  add_foreign_key "possesses", "folders"
  add_foreign_key "possesses", "users"
  add_foreign_key "share_files", "files"
  add_foreign_key "share_files", "users"
  add_foreign_key "share_folders", "folders"
  add_foreign_key "share_folders", "users"
end
