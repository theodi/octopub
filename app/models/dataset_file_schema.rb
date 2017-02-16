# == Schema Information
#
# Table name: dataset_file_schemas
#
#  id          :integer          not null, primary key
#  name        :text
#  description :text
#  url_in_s3   :text
#  url_in_repo :text
#  schema      :json
#  user_id     :integer
#

class DatasetFileSchema < ApplicationRecord
  belongs_to :user
  validates_presence_of :url_in_s3, on: :create, message: 'You must have a schema file'
  validates_presence_of :name, message: 'Please give the schema a meaningful name'

  attr_accessor :parsed_schema

  def parsed_schema
    @parsed_schema ||= DatasetFileSchemaService.get_parsed_schema_from_csv_lint(url)
  end

  def url
    url_in_repo.nil? ? url_in_s3 : url_in_repo
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
end


