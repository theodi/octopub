# == Schema Information
#
# Table name: dataset_file_schemas
#
#  id                    :integer          not null, primary key
#  name                  :text
#  description           :text
#  url_in_s3             :text
#  url_in_repo           :text
#  schema                :json
#  user_id               :integer
#  created_at            :datetime
#  updated_at            :datetime
#  storage_key           :string
#  owner_username        :text
#  owner_avatar_url      :text
#  csv_on_the_web_schema :boolean          default(FALSE)
#

class DatasetFileSchema < ApplicationRecord
  belongs_to :user
  has_and_belongs_to_many :allocated_users, class_name: 'User', join_table: :allocated_dataset_file_schemas_users
  has_and_belongs_to_many :schema_categories, join_table: :schema_categories_dataset_file_schemas
  has_many :dataset_files, dependent: :nullify
  has_many :schema_fields

  validates_presence_of :url_in_s3, on: :create, message: 'You must have a schema file'
  validates_presence_of :name, message: 'Please give the schema a meaningful name'
  validates_presence_of :user_id # Hidden field
  validates_presence_of :owner_username, message: 'Please select an owner for the schema'

  accepts_nested_attributes_for :schema_fields

  attr_accessor :parsed_schema

  def json_table_schema
    @json_table_schema ||= JsonTableSchema::Schema.new(JSON.parse(schema))
  end

  def to_builder
    Jbuilder.new do |json|
      json.ignore_nil!
      json.set! :fields do
        json.array! schema_fields do |schema_field|
          json.name         schema_field.name
          json.description  schema_field.description
          json.title        schema_field.title
          json.type         schema_field.type
          json.format       schema_field.format
          if schema_field.schema_constraint
            json.constraints do
              json.type schema_field.schema_constraint.type
              json.required schema_field.schema_constraint.required
              json.unique schema_field.schema_constraint.unique
              json.minLength schema_field.schema_constraint.min_length
              json.maxLength schema_field.schema_constraint.max_length
              json.maximum schema_field.schema_constraint.maximum
              json.minimum schema_field.schema_constraint.minimum
              json.pattern schema_field.schema_constraint.pattern

            end
          end
        end
      end
    end
  end

  def foreign_keys
    json_table_schema.foreign_keys
  end

  def parsed_schema
    @parsed_schema ||= DatasetFileSchemaService.get_parsed_schema_from_csv_lint(url)
  end

  def url
    url_in_repo.nil? ? url_in_s3 : url_in_repo
  end

  def creator_name
    user.name
  end

  def owner_name
    owner_username
  end

  def count_datasets_using_this_schema
    dataset_files.pluck(:dataset_id).uniq.count
  end

  # TODO maybe persist this?
  def is_schema_otw?
    parsed_schema.class == Csvlint::Csvw::TableGroup
  end

  def is_schema_valid?
    if is_schema_otw?
      return false unless parsed_schema.tables[parsed_schema.tables.keys.first].columns.first
    else
      return false unless parsed_schema.fields.first
    end
    true
  end

  def is_valid?
    errors.add :schema, 'is invalid' unless is_schema_valid?
  end

  def new_is_schema_valid?
    new_parsed_schema.valid?
  end

  def new_parsed_schema
    @new_parsed_schema ||= JsonTableSchema::Schema.new(url)
  end
end
