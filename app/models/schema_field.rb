# == Schema Information
#
# Table name: schema_fields
#
#  id                     :integer          not null, primary key
#  dataset_file_schema_id :integer
#  name                   :text             not null
#  description            :text
#  title                  :text
#  type                   :integer          default(0), not null
#  format                 :text
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#

class SchemaField  < ApplicationRecord
  belongs_to :dataset_file_schema
  has_one :schema_constraint

  # As we have a column called type
  self.inheritance_column = nil

  enum type: [:any, :integer, :string, :array, :time, :date, :datetime, :boolean, :null, :number, :geojson, :geopoint]

  accepts_nested_attributes_for :schema_constraint
end
