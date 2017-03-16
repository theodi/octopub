# == Schema Information
#
# Table name: dataset_file_schemas
#
#  id               :integer          not null, primary key
#  name             :text
#  description      :text
#  url_in_s3        :text
#  url_in_repo      :text
#  schema           :json
#  user_id          :integer
#  created_at       :datetime
#  updated_at       :datetime
#  storage_key      :string
#  owner_username   :text
#  owner_avatar_url :text
#

class DatasetFileSchema < ApplicationRecord
  belongs_to :user
  validates_presence_of :url_in_s3, on: :create, message: 'You must have a schema file'
 # validates_presence_of :storage_key
  validates_presence_of :name, message: 'Please give the schema a meaningful name'
  validates_presence_of :user_id # Hidden field
  validates_presence_of :owner_username, message: 'Please select an owner for the schema'

 # before_validation :set_storage_key

  attr_accessor :parsed_schema

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
