FactoryGirl.define do
  factory :dataset_file do
    title 'My Awesome Dataset'
    description Faker::Company.bs
    mediatype 'text/csv'
    file_sha 'abc123'
    view_sha 'cba321'
    storage_key   'test-data.csv'
    file Rack::Test::UploadedFile.new(File.join(Rails.root, 'spec', 'fixtures', 'test-data.csv'), "text/csv")
    dataset_file_schema { nil }

    after(:build) { |dataset_file|
      skip_callback_if_exists(DatasetFile, :create, :after, :add_to_github)
    }

    trait :with_callback do
      after(:build) { |dataset_file|
        dataset_file.class.set_callback(:create, :after, :add_to_github)
      }
    end
  end
end
