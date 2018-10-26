# == Schema Information
#
# Table name: model_schema_field
#
#  id                :integer          not null, primary key
#  model_id					 :integer
#  name                   :text             not null
#  description            :text
#  title                  :text
#  type                   :integer          default("any"), not null
#  format                 :text
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#

class ModelSchemaField < ApplicationRecord
  belongs_to :model
	has_one :model_schema_constraint
end
