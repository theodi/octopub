FactoryGirl.define do
  factory :user do
    provider "github"
    uid "1234556"
    email   { Faker::Internet.unique.email }
    name    { Faker::Name.unique.name }
    token "rwefsadasfesesds3454353few"
    # use default role, either from ENV or "publisher"

    trait :with_twitter_name do
      after(:build) { |user|
        user.twitter_handle = Faker::Twitter.user[:screen_name]
      }
    end

    factory :publisher do
      role :publisher
    end

    factory :superuser do
      role :superuser
    end

    factory :admin do
      role :admin
    end

    factory :guest do
      role :guest
    end

  end
end
