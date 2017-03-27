require "rails_helper"
require 'features/user_and_organisations'
require 'support/odlifier_licence_mock'

feature "Update dataset page", type: :feature do
  include_context 'user and organisations'
  include_context 'odlifier licence mock'

  let(:data_file) { get_fixture_file('valid-schema.csv') }
  let(:schema_name) { Faker::Lorem.word }
  let(:schema_description) { Faker::Lorem.sentence }
  let(:good_schema_url) { url_with_stubbed_get_for_fixture_file('schemas/good-schema.json') }

  before(:each) do
    visit root_path
    allow_any_instance_of(JekyllService).to receive(:license_details) {
      object = double(Object)
      allow(object).to receive(:url) { 'https://example.org'}
      allow(object).to receive(:title) { 'licence' }
      object
    }
  end

  context "logged in visitor has a dataset and" do

    before(:each) do
      expect(Dataset.count).to be 0
      @dataset = create(:dataset_with_files, user: @user)
      expect(Dataset.count).to be 1
      allow_any_instance_of(Dataset).to receive(:owner_avatar) { "http://example.org/avatar.png" }

      click_link "My datasets"
      expect(page).to have_content "My Datasets"
      expect(page.all('table.table tr').count).to be Dataset.count + 1
      page.find("tr[data-dataset-id='#{@dataset.id}']").click_link('Edit')
      # Bypass sidekiq completely
      allow(UpdateDataset).to receive(:perform_async) do |a,b,c,d,e|
         UpdateDataset.new.perform(a,b,c,d,e)
       end
      allow_any_instance_of(UpdateDataset).to receive(:handle_files) do |a,b|
        {}
      end
      allow(RepoService).to receive(:fetch_repo)
    end

    scenario "can access edit dataset page and change description" do
      expect(page).to have_content "Edit Dataset"
      new_description = Faker::Lorem.sentence
      fill_in 'dataset[description]', with: new_description

      click_on 'Submit'

      @dataset.reload
      expect(page).to have_content ('Your edits have been queued for creation, and your edits should appear on Github shortly.')
      expect(Dataset.count).to be 1
      expect(@dataset.description).to eq new_description
    end
  end

  context "logged in visitor has a dataset with a dataset file schema and" do

    before(:each) do
      expect(Dataset.count).to be 0
      @dataset_file_schema = DatasetFileSchemaService.new(schema_name, schema_description, good_schema_url, @user).create_dataset_file_schema
      good_file = url_with_stubbed_get_for_fixture_file('valid-schema.csv')

      @dataset_file_schema = DatasetFileSchemaService.new(schema_name, schema_description, good_schema_url, @user).create_dataset_file_schema

      @dataset = Dataset.create(name: Faker::Lorem.word, description: Faker::Lorem.sentence, user: @user)
      @dataset_file = DatasetFile.new(title: Faker::Lorem.word, description: Faker::Lorem.sentence, file: good_file, dataset_file_schema: @dataset_file_schema, dataset: @dataset, storage_key: 'valid-schema.csv' )
      @dataset_file.save(validate: false)

      expect(Dataset.count).to be 1
      allow_any_instance_of(DatasetFile).to receive(:check_schema)
      allow_any_instance_of(Dataset).to receive(:owner_avatar) { "http://example.org/avatar.png" }
      allow_any_instance_of(Dataset).to receive(:update_dataset_in_github)

      click_link "My datasets"
      expect(page).to have_content "My Datasets"
      expect(page.all('table.table tr').count).to be Dataset.count + 1
      page.find("tr[data-dataset-id='#{@dataset.id}']").click_link('Edit')
      # Bypass sidekiq completely
      allow(UpdateDataset).to receive(:perform_async) do |a,b,c,d,e|
         UpdateDataset.new.perform(a,b,c,d,e)
       end
      allow_any_instance_of(UpdateDataset).to receive(:handle_files) do |a,b|
        {}
      end
      allow(RepoService).to receive(:fetch_repo)
    end

    scenario "can access edit dataset page and change description" do

      expect(page).to have_content "Edit Dataset"
      new_description = Faker::Lorem.sentence
      fill_in 'dataset[description]', with: new_description

      click_on 'Submit'

      @dataset.reload
      expect(page).to have_content ('Your edits have been queued for creation, and your edits should appear on Github shortly.')
      expect(Dataset.count).to be 1
      expect(@dataset.description).to eq new_description
    end
  end
end
