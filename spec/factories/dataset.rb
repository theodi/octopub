FactoryGirl.define do
  factory :dataset do
    name "My Awesome Dataset"
    description "An awesome dataset"
    publisher_name "Awesome Inc"
    publisher_url "http://awesome.com"
    license "OGL-UK-3.0" # BTW This is currently hardcoded for VCR purposes
    frequency { Octopub::PUBLICATION_FREQUENCIES.sample }

    association :user, factory: :user

    after(:build) { |dataset|
      skip_callback_if_exists( Dataset, :create, :after, :create_repo_and_populate)
      skip_callback_if_exists( Dataset, :update, :after, :update_dataset_in_github)
      dataset.instance_variable_set(:@repo, FakeData.new)
    }

    trait :with_callback do
      after(:build) { |dataset|
        dataset.class.set_callback(:create, :after, :create_repo_and_populate)
        dataset.class.set_callback(:update, :after, :update_dataset_in_github)
      }
    end
  end
end
