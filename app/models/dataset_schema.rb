# == Schema Information
#
# Table name: dataset_schemas
#
#  id          :integer          not null, primary key
#  name        :text
#  description :text
#  url_in_s3   :text
#  url_in_repo :text
#  schema      :json
#  user_id     :integer
#

class DatasetSchema < ApplicationRecord
  belongs_to :user

  attr_accessor :parsed_schema

  def parsed_schema
    @parsed_schema ||= DatasetSchemaService.get_parsed_schema_from_csv_lint(url)
  end

  def url
    url_in_repo.nil? ? url_in_s3 : url_in_repo
  end

  # TODO maybe persist this?
  def is_schema_otw?
    parsed_schema.class == Csvlint::Csvw::TableGroup
  end

  def is_valid?(dataset_errors)
    if is_schema_otw?
      unless parsed_schema.tables[parsed_schema.tables.keys.first].columns.first
        dataset_errors.add :schema, 'is invalid'
      end
    else
      unless parsed_schema.fields.first
        dataset_errors.add :schema, 'is invalid'
      end
    end
  end
end
