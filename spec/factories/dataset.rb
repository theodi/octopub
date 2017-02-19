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
      skip_callback_if_exists( Dataset, :create, :after, :create_repo_and_populate)
      skip_callback_if_exists( Dataset, :create, :after, :publish_public_views)
      skip_callback_if_exists( Dataset, :create, :after, :send_success_email)
      skip_callback_if_exists( Dataset, :update, :after, :update_dataset_in_github)
      skip_callback_if_exists( Dataset, :create, :after, :set_owner_avatar)
      dataset.instance_variable_set(:@repo, FakeData.new)
    }

    trait :with_callback do
      after(:build) { |dataset|
        dataset.class.set_callback(:create, :after, :create_repo_and_populate)
        dataset.class.set_callback(:create, :after, :publish_public_views)
        dataset.class.set_callback(:update, :after, :update_dataset_in_github)
      }
    end

    trait :with_avatar_callback do
      after(:build) { |dataset|
        dataset.class.set_callback(:create, :after, :set_owner_avatar)
      }
    end


  end


end
