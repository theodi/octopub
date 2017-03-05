# require_relative "../features/user_and_organisations.rb"
# require_relative "../spec_helper.rb"
# require_relative "../rails_helper.rb"
require 'webmock/rspec'

FactoryGirl.define do
  factory :dataset_file do
    title 'My Awesome Dataset'
    description Faker::Company.bs
    mediatype 'text/csv'
    file_sha 'abc123'
    view_sha 'cba321'
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

    # factory :dataset_file_with_schema do
    #   file Rack::Test::UploadedFile.new(File.join(Rails.root, 'spec', 'fixtures', 'valid-schema.csv'), "text/csv")
    #   dataset_file_schema { create(:dataset_file_schema, url_in_s3:  Rack::Test::UploadedFile.new(File.join(Rails.root, 'spec', 'fixtures', 'schemas/good-schema.json'), "text/json")) }
    # end
  end
end

# def url_with_stubbed_get_for_fixture_file(file_name)
#   path = File.join(Rails.root, 'spec', 'fixtures', file_name)
#   url = "https://example.org/uploads/#{SecureRandom.uuid}/somefile.csv"
#   stub_request(:get, url).to_return(body: File.read(path))
#   url
# end
