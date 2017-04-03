class OutputSchemaField < ApplicationRecord
  belongs_to :output_schema
  belongs_to :schema_field

  # Of course, sum, group_by and names like that break in rails
  enum aggregation_type: [:ignoring, :totaling, :grouping]


end
