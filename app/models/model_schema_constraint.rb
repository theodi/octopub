# == Schema Information
#
# Table name: model_schema_constraint
#
#  id                			:integer          not null, primary key
#  description						:text
#  model_schema_field_id  :integer
#  required        				:boolean
#  unique          				:boolean
#  min_length      				:integer
#  max_length      				:integer
#  minimum         				:text
#  maximum         				:text
#  pattern         				:text
#  type            				:text
#

class ModelSchemaConstraint < ApplicationRecord
  belongs_to :model_schema_field
end
