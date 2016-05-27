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
      dataset.class.skip_callback(:create, :after, :create_in_github)
      dataset.class.skip_callback(:update, :after, :update_in_github)
      dataset.class.skip_callback(:create, :after, :set_owner_avatar)

      dataset.instance_variable_set(:@repo, FakeData.new)
    }

    trait :with_callback do
      after(:build) { |dataset|
        dataset.class.set_callback(:create, :after, :create_in_github)
        dataset.class.set_callback(:update, :after, :update_in_github)
      }
    end

    trait :with_avatar_callback do
      after(:build) { |dataset|
        dataset.class.set_callback(:create, :after, :set_owner_avatar)
      }
    end
  end
end
