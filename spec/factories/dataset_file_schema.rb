FactoryBot.define do
  factory :dataset_file_schema do
    name Faker::Name.unique.name
    description Faker::Company.bs
    url_in_s3 Faker::Internet.url('example.com')
    user
    owner_username { user.name }

    factory :organisation_owned_dataset_file_schema do
      owner_username Faker::Internet.user_name
    end
  end
end
