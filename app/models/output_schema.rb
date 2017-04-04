# == Schema Information
#
# Table name: output_schemas
#
#  id                     :integer          not null, primary key
#  dataset_file_schema_id :integer
#  user_id                :integer
#  owner_username         :text
#  title                  :text
#  description            :text
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#

class OutputSchema < ApplicationRecord
  belongs_to :dataset_file_schema
  belongs_to :user

  has_many :output_schema_fields
  has_many :schema_fields, through: :output_schema_fields

  validates_presence_of :title

  accepts_nested_attributes_for :output_schema_fields

  def grouping_schema_fields
    output_schema_fields.includes(:schema_field).grouping.map { |output_schema_field| output_schema_field.schema_field }
  end

  def totaling_schema_fields
    output_schema_fields.includes(:schema_field).totaling.map { |output_schema_field| output_schema_field.schema_field }
  end
end
