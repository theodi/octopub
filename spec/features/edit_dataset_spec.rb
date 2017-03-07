require "rails_helper"
require 'features/user_and_organisations'

feature "Add dataset page", type: :feature, vcr: { :match_requests_on => [:host, :method] } do
  include_context 'user and organisations'

  let(:data_file) { get_fixture_file('valid-schema.csv') }
  let(:schema_file) { get_fixture_schema_file('good-schema.json') }
  let(:dataset_name) { Faker::Lorem.word }
  let(:dataset_file_name) { Faker::Lorem.word }
  let(:dataset_file_description) { Faker::Lorem.sentence }

  before(:each) do
    skip_callback_if_exists(Dataset, :create, :after, :create_repo_and_populate)
    good_schema_url = url_with_stubbed_get_for_fixture_file('schemas/good-schema.json')
    create(:dataset_file_schema, url_in_repo: good_schema_url, name: 'good schema', description: 'good schema description', user: @user)
    @dataset = create(:dataset, name: dataset_name)
    file = create(:dataset_file, dataset_file_schema: @dataset_file_schema,
                                  filename: "example.csv",
                                  title: dataset_file_name,
                                  description: dataset_file_description,
                                  file: Rack::Test::UploadedFile.new(data_file, "text/csv"),
                                  dataset: @dataset)
    allow_any_instance_of(Dataset).to receive(:owner_avatar) {
      "http://example.org/avatar.png"
    }
    expect(DatasetFileSchema.count).to be 1
    expect(DatasetFile.count).to be 1
    expect(Dataset.count).to be 1
    visit root_path
  end

  context "logged in visitor has datasets and" do
    scenario "can view them" do
      visit datasets_path
      expect(page).to have_content dataset_name
      expect(page).to have_content 'Edit'
    end
  end
end

