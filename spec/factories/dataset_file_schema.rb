FactoryGirl.define do
  factory :dataset_file_schema do
    name 'My Amazing Schema'
    description Faker::Company.bs
    user

    after(:build) do |obj|
      obj.schema = "hello!"
    end
  end

  # factory :dataset_file_schema_otw do
  #   name 'My Amazing Schema'
  #   description Faker::Company.bs











  # end




end

# == Schema Information
#
# Table name: dataset_file_schemas
#
#  id          :integer          not null, primary key
#  name        :text
#  description :text
#  url_in_s3   :text
#  url_in_repo :text
#  schema      :json
#  user_id     :integer
#