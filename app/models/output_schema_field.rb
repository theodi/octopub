class OutputSchemaField < ApplicationRecord
  belongs_to :output_schema
  belongs_to :schema_field

  # Of course, sum, group_by and names like that break in rails
  enum aggregation_type: [:ignoring, :totaling, :grouping]

  def self.friendly_aggregation_types
    friendly_hash = { ignoring: 'Ignore this field', totaling: 'Sum this field', grouping: 'Group by this field' }
    aggregation_types.map {|type_name, _type_integer| [friendly_hash[type_name.to_sym], type_name]}
  end
end
