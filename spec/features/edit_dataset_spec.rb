require "rails_helper"
require 'features/user_and_organisations'

feature "Edit dataset page", type: :feature, vcr: { :match_requests_on => [:host, :method] } do
  include_context 'user and organisations'

  let(:data_file) { get_fixture_file('valid-schema.csv') }
  let(:schema_file) { get_fixture_schema_file('good-schema.json') }
  let(:dataset_name) { Faker::Lorem.word }
  let(:dataset_description) { Faker::Lorem.sentence }
  let(:dataset_file_name) { Faker::Lorem.word }
  let(:dataset_file_description) { Faker::Lorem.sentence }

  before(:each) do
    allow(UpdateDataset).to receive(:perform_async) do |a,b,c,d,e|
      UpdateDataset.new.perform(a,b,c,d,e)
    end

    skip_callback_if_exists(Dataset, :create, :after, :create_repo_and_populate)
    good_schema_url = url_with_stubbed_get_for_fixture_file('schemas/good-schema.json')
    create(:dataset_file_schema, url_in_repo: good_schema_url, name: 'good schema', description: 'good schema description', user: @user)
    @dataset = create(:dataset, name: dataset_name, user: @user, license: "CC-BY-4.0", description: dataset_description)
    file = create(:dataset_file, dataset_file_schema: @dataset_file_schema,
                                  filename: "example.csv",
                                  title: dataset_file_name,
                                  description: dataset_file_description,
                                  file: Rack::Test::UploadedFile.new(data_file, "text/csv"),
                                  dataset: @dataset)
    allow_any_instance_of(Dataset).to receive(:owner_avatar) {
      "http://example.org/avatar.png"
    }
    @dataset.reload

    allow_any_instance_of(UpdateDataset).to receive(:get_dataset).with(@dataset.id.to_s, @user) {
      @dataset
    }
    expect(DatasetFileSchema.count).to be 1
    expect(DatasetFile.count).to be 1
    expect(Dataset.count).to be 1
    expect(Dataset.first.dataset_files.count).to be 1

    visit dashboard_path
    expect(page).to have_content dataset_name
    expect(page).to have_content 'Edit'
    click_link 'Edit'

    expect(page).to have_content 'Edit Dataset'
  end

  context "logged in visitor has datasets and" do
    scenario "can edit the description" do
      new_description = Faker::Lorem.sentence
      fill_in 'dataset[description]', with: new_description
      click_on 'Submit'
      expect(page).to have_content 'Your edits have been queued for creation'
      @dataset.reload
      expect(@dataset.description).to eq new_description
    end

    scenario "can edit the file description" do
      new_description = Faker::Lorem.sentence
      within 'div.visible' do
        fill_in 'files[][description]', with: new_description
      end
      #expect_any_instance_of(RepoService).to receive(:save)
      click_on 'Submit'
      expect(page).to have_content 'Your edits have been queued for creation'
      @dataset.reload
      expect(@dataset.dataset_files.first.description).to eq new_description
    end
  end
end

