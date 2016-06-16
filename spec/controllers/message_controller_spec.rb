require 'spec_helper'
require 'spec_helpers/spec_helper_event'
require 'sidekiq/testing'
Sidekiq::Testing.inline!

describe 'MessageController', type: :controller do

  before(:each) do
    @user = create(:user, name: "User McUser", email: "user@user.com")

    @name = "My cool dataset"
    @description = "This is a description"
    @publisher_name = "Cool inc"
    @publisher_url = "http://example.com"
    @license = "OGL-UK-3.0"
    @frequency = "Monthly"

    Dataset.skip_callback(:create, :after, :create_in_github)
    Dataset.skip_callback(:create, :after, :set_owner_avatar)

    allow_any_instance_of(DatasetFile).to receive(:add_to_github) { nil }
    allow_any_instance_of(Dataset).to receive(:create_files) { nil }
  end

  it 'creates a dataset' do
    @user = create(:user, name: "User McUser", email: "user@user.com")
    filename = 'test-data.csv'
    path = File.join(Rails.root, 'spec', 'fixtures', filename)

    message = {
      "user" => @user.id,
      "dataset" => {
        "name" => @name,
        "description" => @description,
        "publisher_name" => @publisher_name,
        "publisher_url" => @publisher_url,
        "license" => @license,
        "frequency" => @frequency
      },
      "files" => [
        {
          "title" => "File Title",
          "description" => "File Description",
          "file" => fake_file(path)
        }
      ]
    }.to_query

    event = create_event('datasets.create', message)
    event.dispatch

    expect(Dataset.count).to eq(1)
  end

end
