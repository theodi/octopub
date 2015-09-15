FactoryGirl.define do
  factory :user do
    provider "github"
    uid "1234556"
    email "user@example.com"
    name "User"
    token "rwefsadasfesesds3454353few"
  end
end
