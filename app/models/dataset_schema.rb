# == Schema Information
#
# Table name: dataset_schemas
#
#  id          :integer          not null, primary key
#  name        :text
#  description :text
#  url_in_s3   :text
#  url_in_repo :text
#  schema      :json
#  user_id     :integer
#

class DatasetSchema < ApplicationRecord
  belongs_to :user
  
  attr_accessor :parsed_schema

end
