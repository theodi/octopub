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

ActiveRecord::Schema.define(version: 20170315152041) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "allocated_dataset_file_schemas_users", id: false, force: :cascade do |t|
    t.integer "dataset_file_schema_id"
    t.integer "user_id"
    t.index ["dataset_file_schema_id"], name: "allocated_dataset_file_schema_index", using: :btree
    t.index ["user_id"], name: "allocated_user_index", using: :btree
  end

  create_table "dataset_file_schemas", force: :cascade do |t|
    t.text     "name"
    t.text     "description"
    t.text     "url_in_s3"
    t.text     "url_in_repo"
    t.json     "schema"
    t.integer  "user_id"
    t.string   "storage_key"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["user_id"], name: "index_dataset_file_schemas_on_user_id", using: :btree
  end

  create_table "dataset_files", force: :cascade do |t|
    t.string   "title",                  limit: 255
    t.string   "filename",               limit: 255
    t.string   "mediatype",              limit: 255
    t.integer  "dataset_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "description"
    t.text     "file_sha"
    t.text     "view_sha"
    t.integer  "dataset_file_schema_id"
    t.string   "storage_key"
    t.text     "owner_username"
    t.text     "owner_avatar_url"
    t.index ["dataset_file_schema_id"], name: "index_dataset_files_on_dataset_file_schema_id", using: :btree
    t.index ["dataset_id"], name: "index_dataset_files_on_dataset_id", using: :btree
  end

  create_table "datasets", force: :cascade do |t|
    t.string   "name",            limit: 255
    t.string   "url",             limit: 255
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "repo",            limit: 255
    t.text     "description"
    t.string   "publisher_name",  limit: 255
    t.string   "publisher_url",   limit: 255
    t.string   "license",         limit: 255
    t.string   "frequency",       limit: 255
    t.text     "datapackage_sha"
    t.string   "owner",           limit: 255
    t.string   "owner_avatar",    limit: 255
    t.string   "build_status",    limit: 255
    t.string   "full_name",       limit: 255
    t.string   "certificate_url", limit: 255
    t.string   "job_id",          limit: 255
    t.boolean  "restricted",                    default: false
    t.index ["user_id"], name: "index_datasets_on_user_id", using: :btree
  end

  create_table "errors", force: :cascade do |t|
    t.string "job_id",   limit: 255, null: false
    t.json   "messages"
  end

  create_table "users", force: :cascade do |t|
    t.string   "provider",        limit: 255
    t.string   "uid",             limit: 255
    t.string   "email",           limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name",            limit: 255
    t.string   "token",           limit: 255
    t.string   "api_key",         limit: 255
    t.text     "org_dataset_ids",             default: [], array: true
    t.string   "twitter_handle",  limit: 255
    t.integer  "role",            default: 0,  null: false
  end

end
