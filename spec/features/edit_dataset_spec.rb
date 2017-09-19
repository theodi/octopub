require "rails_helper"
require 'features/user_and_organisations'
require 'support/odlifier_licence_mock'

feature "Edit dataset page", type: :feature do
  include_context 'user and organisations'
  include_context 'odlifier licence mock'

  let(:data_file) { get_fixture_file('valid-schema.csv') }
  let(:schema_file) { get_fixture_schema_file('good-schema.json') }
  let(:dataset_name) { Faker::Lorem.word }
  let(:dataset_description) { Faker::Lorem.sentence }
  let(:dataset_file_name) { Faker::Lorem.word }
  let(:dataset_file_description) { Faker::Lorem.sentence }

  before(:each) do
    allow(UpdateDataset).to receive(:perform_async) do |a,b,c,d|
      UpdateDataset.new.perform(a,b,c,d)
    end
    @another_user = create(:user, name: "A. N. Other")
    good_schema_url = url_with_stubbed_get_for_fixture_file('schemas/good-schema.json')
    @dataset_file_schema = create(:dataset_file_schema, url_in_repo: good_schema_url, name: 'good schema', description: 'good schema description', user: @user)
    @dataset = create(:dataset, name: dataset_name, user: @user, license: "CC-BY-4.0", description: dataset_description)
    file = create(:dataset_file, dataset_file_schema: @dataset_file_schema,
                                  filename: "example.csv",
                                  title: dataset_file_name,
                                  description: dataset_file_description,
                                  file: Rack::Test::UploadedFile.new(data_file, "text/csv"),
                                  dataset: @dataset,
                                  storage_key: "valid-schema.csv")
    allow_any_instance_of(Dataset).to receive(:owner_avatar) {
      "http://example.org/avatar.png"
    }
    @dataset.reload

    allow_any_instance_of(UpdateDataset).to receive(:get_dataset).with(@dataset.id.to_s) {
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

    scenario "can change the user" do
      # select by ID, because of bootstrap selects hiding the text itself at this level
      select @another_user.github_username, from: '_dataset[user_id]'
      click_on 'Submit'
      expect(page).to have_content 'Your edits have been queued for creation'
      @dataset.reload
      expect(@dataset.user).to eq @another_user
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
    
    scenario "has an existing schema preselected in the new file form" do
      within '.hidden > .file-panel' do
        expect(find_field("_files[][dataset_file_schema_id]").value).to eql @dataset.dataset_files.first.dataset_file_schema_id.to_s
      end
    end
    
  end
end
