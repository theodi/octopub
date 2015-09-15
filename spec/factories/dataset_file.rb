FactoryGirl.define do
  factory :dataset_file do
    title 'My Awesome Dataset'
    filename 'dataset.csv'
    description Faker::Company.bs
    mediatype 'text/csv'

    after(:build) { |dataset_file|
      dataset_file.class.skip_callback(:create, :after, :add_to_github)
    }

    trait :with_callback do
      after(:build) { |dataset_file|
        dataset_file.class.set_callback(:create, :after, :add_to_github)
      }
    end
  end
end
