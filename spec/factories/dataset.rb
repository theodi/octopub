FactoryGirl.define do
  factory :dataset do
    name "My Awesome Dataset"
    description "An awesome dataset"
    publisher_name "Awesome Inc"
    publisher_url "http://awesome.com"
    license "OGL-UK-3.0"
    frequency "One-off"

    association :user, factory: :user

    after(:build) { |dataset|
      dataset.class.skip_callback(:create, :before, :create_in_github)
    }

    trait :with_callback do
      after(:build) { |dataset|
        dataset.class.set_callback(:create, :before, :create_in_github)
      }
    end
  end
end
