FactoryGirl.define do
  factory :dataset do
    name "My Awesome Dataset"
    url  "https://github.com/user/my-awesome-dataset"
    repo "my-awesome-dataset"
    description "An awesome dataset"
    publisher_name "Awesome Inc"
    publisher_url "http://awesome.com"
    license "OGL-UK-3.0"
    frequency "One-off"

    association :user, factory: :user
  end
end
