# == Schema Information
#
# Table name: schema_constraints
#
#  id              :integer          not null, primary key
#  schema_field_id :integer
#  required        :boolean          default(FALSE)
#  unique          :boolean          default(FALSE)
#  min_length      :integer
#  max_length      :integer
#  minimum         :integer
#  maximum         :integer
#  pattern         :text
#  type            :text
#

class SchemaConstraint < ApplicationRecord

  # As we have a column called type
  self.inheritance_column = nil

  belongs_to :schema_field

  def initialize(value)
    # JSON table schema can output attributes as camel case, which we don't want.
    new_hash = value.transform_keys { |key| key.to_s.underscore }
    super(new_hash)
  end
end
