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

ActiveRecord::Schema.define(version: 2018_07_10_110526) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "allocated_dataset_file_schemas_users", id: false, force: :cascade do |t|
    t.integer "dataset_file_schema_id"
    t.integer "user_id"
    t.index ["dataset_file_schema_id"], name: "allocated_dataset_file_schema_index"
    t.index ["user_id"], name: "allocated_user_index"
  end

  create_table "dataset_file_schemas", id: :serial, force: :cascade do |t|
    t.text "name"
    t.text "description"
    t.text "url_in_s3"
    t.text "url_in_repo"
    t.json "schema"
    t.integer "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "storage_key"
    t.text "owner_username"
    t.text "owner_avatar_url"
    t.boolean "csv_on_the_web_schema", default: false
    t.boolean "restricted", default: true
    t.index ["user_id"], name: "index_dataset_file_schemas_on_user_id"
  end

  create_table "dataset_files", id: :serial, force: :cascade do |t|
    t.string "title"
    t.string "filename"
    t.string "mediatype"
    t.integer "dataset_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text "description"
    t.text "file_sha"
    t.text "view_sha"
    t.integer "dataset_file_schema_id"
    t.string "storage_key"
    t.boolean "validation"
    t.index ["dataset_file_schema_id"], name: "index_dataset_files_on_dataset_file_schema_id"
    t.index ["dataset_id"], name: "index_dataset_files_on_dataset_id"
  end

  create_table "datasets", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "url"
    t.integer "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "repo"
    t.text "description"
    t.string "publisher_name"
    t.string "publisher_url"
    t.string "license"
    t.string "frequency"
    t.text "datapackage_sha"
    t.string "owner"
    t.string "owner_avatar"
    t.string "build_status"
    t.string "full_name"
    t.string "certificate_url"
    t.string "job_id"
    t.integer "publishing_method", default: 0, null: false
    t.datetime "url_deprecated_at"
    t.text "published_status", default: "unpublished"
    t.index ["user_id"], name: "index_datasets_on_user_id"
  end

  create_table "errors", id: :serial, force: :cascade do |t|
    t.string "job_id", null: false
    t.json "messages"
  end

  create_table "output_schema_fields", id: :serial, force: :cascade do |t|
    t.integer "output_schema_id"
    t.integer "schema_field_id"
    t.integer "aggregation_type", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["aggregation_type"], name: "index_output_schema_fields_on_aggregation_type"
    t.index ["output_schema_id"], name: "index_output_schema_fields_on_output_schema_id"
    t.index ["schema_field_id"], name: "index_output_schema_fields_on_schema_field_id"
  end

  create_table "output_schemas", id: :serial, force: :cascade do |t|
    t.integer "dataset_file_schema_id"
    t.integer "user_id"
    t.text "owner_username"
    t.text "title"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["dataset_file_schema_id"], name: "index_output_schemas_on_dataset_file_schema_id"
    t.index ["user_id"], name: "index_output_schemas_on_user_id"
  end

  create_table "schema_categories", id: :serial, force: :cascade do |t|
    t.text "name", null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "schema_categories_dataset_file_schemas", id: false, force: :cascade do |t|
    t.integer "dataset_file_schema_id"
    t.integer "schema_category_id"
    t.index ["dataset_file_schema_id"], name: "schema_category_index"
    t.index ["schema_category_id"], name: "dataset_file_schema_index"
  end

  create_table "schema_constraints", id: :serial, force: :cascade do |t|
    t.integer "schema_field_id"
    t.boolean "required"
    t.boolean "unique"
    t.integer "min_length"
    t.integer "max_length"
    t.text "minimum"
    t.text "maximum"
    t.text "pattern"
    t.text "type"
    t.string "date_pattern"
    t.index ["schema_field_id"], name: "index_schema_constraints_on_schema_field_id"
  end

  create_table "schema_fields", id: :serial, force: :cascade do |t|
    t.integer "dataset_file_schema_id"
    t.text "name", null: false
    t.text "description"
    t.text "title"
    t.integer "type", default: 0, null: false
    t.text "format"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["dataset_file_schema_id"], name: "index_schema_fields_on_dataset_file_schema_id"
  end

  create_table "users", id: :serial, force: :cascade do |t|
    t.string "provider"
    t.string "uid"
    t.string "email"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "name"
    t.string "token"
    t.string "api_key"
    t.text "org_dataset_ids", default: [], array: true
    t.string "twitter_handle"
    t.integer "role", default: 0, null: false
    t.boolean "restricted", default: false
  end

end
