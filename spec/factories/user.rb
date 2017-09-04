FactoryGirl.define do
  factory :user do
    email   { Faker::Internet.unique.email }
    name    { Faker::Name.unique.name }
    password { Devise.friendly_token[0,20] }

    token "rwefsadasfesesds3454353few"
    role { :publisher }

    trait :with_twitter_name do
      after(:build) { |user|
        user.twitter_handle = Faker::Twitter.user[:screen_name]
      }
    end

    factory :superuser do
      role :superuser
    end

    factory :admin do
      role :admin
    end
    
    factory :github_user do
      token { Faker::Crypto.md5 }
      provider "github"
      uid "1234556"
    end

  end
end