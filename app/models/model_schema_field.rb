# == Schema Information
#
# Table name: model_schema_field
#
#  id                			:integer          not null, primary key
#  model_id					 			:integer
#  name                   :text             not null
#  description            :text
#  title                  :text
#  type                   :integer          default("any"), not null
#  format                 :text
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#

class ModelSchemaField < ApplicationRecord

	self.inheritance_column = nil

  belongs_to :model
	has_one :model_schema_constraint

	accepts_nested_attributes_for :model_schema_constraint

	enum type: [:any, :string, :integer, :float, :double, :URL, :boolean,
		:non_positive_integer, :positive_integer, :non_negative_integer,
		:negative_integer, :date, :date_and_time, :year, :year_and_month, :time]

	def constraint_string(constraint)
		constraint
	end

end
