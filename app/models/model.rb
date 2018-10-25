# == Schema Information
#
# Table name: models
#
#  id                :integer          not null, primary key
#  name              :string
#  description       :text
#  created_at        :datetime
#  updated_at        :datetime

class Model < ApplicationRecord
	include Publishable
	
  belongs_to :user
end
