class OutputSchema < ApplicationRecord
  belongs_to :dataset_file_schema
  has_many :output_schema_fields
  has_many :schema_fields, through: :output_schema_fields

  accepts_nested_attributes_for :output_schema_fields

  def grouping_schema_fields
    output_schema_fields.includes(:schema_field).grouping.map { |output_schema_field| output_schema_field.schema_field }
  end

  def totaling_schema_fields
    output_schema_fields.includes(:schema_field).totaling.map { |output_schema_field| output_schema_field.schema_field }
  end
end
