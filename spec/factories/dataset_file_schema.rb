FactoryGirl.define do
  factory :dataset_file_schema do
    name 'My Amazing Schema'
    description Faker::Company.bs
    user
  end
end