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
      dataset.class.skip_callback(:save, :before, :push_to_github)
      dataset.instance_variable_set(:@repo, GitData.new(nil, dataset.name, dataset.user.name))
    }

    trait :with_callback do
      after(:build) { |dataset|
        dataset.class.set_callback(:create, :before, :create_in_github)
      }
    end

    trait :with_push_callback do
      after(:build) { |dataset|
        dataset.class.set_callback(:save, :before, :push_to_github)
        dataset.instance_variable_set(:@repo, GitData.new(nil, dataset.name, dataset.user.name))
      }
    end
  end
end
