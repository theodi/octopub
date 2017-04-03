class OutputSchemaField < ApplicationRecord
  belongs_to :output_schema
  belongs_to :schema_field

  # Of course, sum, group_by and names like that break in rails
  enum aggregation_type: [:ignoring, :totaling, :grouping]

  FRIENDLY_HASH = { ignoring: 'Ignore this field', totaling: 'Sum this field', grouping: 'Group by this field' }

  def self.friendly_aggregation_types
    aggregation_types.map {|type_name, _type_integer| [FRIENDLY_HASH[type_name.to_sym], type_name]}
  end

  def friendly_aggregation_type
    FRIENDLY_HASH[aggregation_type.to_sym]
  end
end
