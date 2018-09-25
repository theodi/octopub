require "rails_helper"
require 'features/user_and_organisations'
require 'support/odlifier_licence_mock'

feature "Add dataset page", type: :feature do
  include_context 'user and organisations'
  include_context 'odlifier licence mock'

  let(:data_file) { get_fixture_file('valid-schema.csv') }

  before(:each) do
    allow_any_instance_of(DatasetsController).to receive(:current_user) { @user }
    Sidekiq::Testing.inline!
    visit root_path
  end

  after(:each) do
    Sidekiq::Testing.fake!
  end

  context "logged in visitors has no schemas" do
    pending "and can complete a simple dataset form without adding a schema" do

      repo = double(GitData)
      expect(repo).to receive(:html_url) { 'https://example.org' }
      expect(repo).to receive(:name) { 'examplename'}
      expect(repo).to receive(:full_name) { 'examplename' }
      expect(RepoService).to receive(:create_repo) { repo }
      expect(RepoService).to receive(:fetch_repo).at_least(:once) { repo }
      expect(RepoService).to receive(:prepare_repo).at_least(:once)
      click_link "Create a new data collection"

      allow(DatasetFile).to receive(:read_file_with_utf_8).and_return(File.read(data_file))

      expect_any_instance_of(JekyllService).to receive(:create_data_files) { nil }

      common_name = 'Fri1437'

      before_datasets = Dataset.count
      expect(page).to have_selector(:link_or_button, "Submit")
      within 'form' do
        expect(page).to have_content @user.github_username
        complete_form(page, common_name, data_file)
      end

      click_on 'Submit'

      expect(page).to have_content "Your dataset has been queued for creation, and you should receive an email with a link to your dataset on Github shortly."
      expect(Dataset.count).to be before_datasets + 1
      expect(Dataset.last.name).to eq "#{common_name}-name"
      expect(Dataset.last.owner).to eq @user.github_username
    end

  end

  def complete_form(page, common_name, data_file, owner = nil, licence = nil)

    dataset_name = "#{common_name}-name"

    fill_in 'dataset[name]', with: dataset_name
    fill_in 'dataset[description]', with: "#{common_name}-description"
		click_on 'Next: Add a licence'

		find('input[value="CC-BY-4.0"]').click
		click_on 'Next: Add your file(s)'

    fill_in 'files__title', with: "#{common_name}-file-name"
    fill_in 'files[][description]', with: "#{common_name}-file-description"
    attach_file("[files[][file]]", data_file)
    expect(page).to have_selector("input[value='#{dataset_name}']")
		expect(page).to have_content("FOO")
  end
end
