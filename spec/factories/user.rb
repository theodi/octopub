FactoryGirl.define do
  factory :user do
    provider "github"
    uid "1234556"
    email   { Faker::Internet.unique.email }
    name    { Faker::Name.unique.name }
    token "rwefsadasfesesds3454353few"
    #password "this-has-to-be-longer-than-six-characters"
  end
end
