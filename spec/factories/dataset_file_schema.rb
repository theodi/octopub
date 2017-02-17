FactoryGirl.define do
  factory :dataset_file_schema do
    name 'My Amazing Schema'
    description Faker::Company.bs
    url_in_s3 Faker::Internet.url('example.com')
    user
  end
end
