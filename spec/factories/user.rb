FactoryGirl.define do
  factory :user do
    provider "github"
    uid "1234556"
    email   { Faker::Internet.unique.email }
    name    { Faker::Name.unique.name }
    token "rwefsadasfesesds3454353few"
 
    trait :with_twitter_name do
      after(:build) { |user|
        user.twitter_handle = Faker::Twitter.user[:name]
      }
    end
  end
end
