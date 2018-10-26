# == Schema Information
#
# Table name: model_schema_fields
#

class ModelSchemaField < ApplicationRecord
  belongs_to :model
end
