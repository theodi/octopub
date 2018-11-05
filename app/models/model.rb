# == Schema Information
#
# Table name: models
#
#  id                :integer          not null, primary key
#  name              :string
#  description       :text
#  schema            :json
#  user_id           :integer
#  url_in_s3				 :text
#  storage_key       :string
#  created_at        :datetime
#  updated_at        :datetime

class Model < ApplicationRecord
  belongs_to :user
	has_many :model_schema_fields

	accepts_nested_attributes_for :model_schema_fields

	validates_presence_of :user_id # Hidden field

end
