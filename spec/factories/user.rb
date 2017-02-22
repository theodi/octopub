FactoryGirl.define do
  factory :user do
    email   { Faker::Internet.unique.email }
    name    { Faker::Name.unique.name }
    password { Devise.friendly_token[0,20] }

    factory :github_user do
      token { Faker::Crypto.md5 }
      provider "github"
      uid "1234556"
    end
  end
end
