require "rails_helper"
require 'features/user_and_organisations'
require 'support/odlifier_licence_mock'

feature "Add private github dataset page", type: :feature do
  include_context 'user and organisations'
  include_context 'odlifier licence mock'

  let(:data_file) { get_fixture_file('valid-schema.csv') }

  before(:each) do
    repo = double(GitData)
    expect(repo).to receive(:html_url) { 'https://example.org' }
    expect(repo).to receive(:name) { 'examplename'}
    expect(repo).to receive(:full_name) { 'examplename' }

    expect(RepoService).to receive(:create_repo) { repo }
    expect(RepoService).to receive(:fetch_repo).at_least(:once) { repo }
    Sidekiq::Testing.inline!
    visit root_path
  end

  after(:each) do
    Sidekiq::Testing.fake!
  end

  it "by completing a simple dataset form without adding a schema" do
    click_link "Add dataset"

    expect_any_instance_of(JekyllService).to receive(:create_data_files) { nil }
    expect_any_instance_of(JekyllService).to receive(:push_to_github) { nil }
    expect_any_instance_of(JekyllService).to_not receive(:create_public_views) { nil }
    expect_any_instance_of(Dataset).to receive(:send_success_email) { nil }

    common_name = 'Fri1437'

    before_datasets = Dataset.count
    expect(page).to have_selector(:link_or_button, "Submit")
    within 'form' do
      expect(page).to have_content @user.github_username
      expect(page).to have_content "Upload a schema for this Data File"
      complete_form(page, common_name, data_file)
    end

    click_on 'Submit'

    expect(page).to have_content "Your dataset has been queued for creation, and you should receive an email with a link to your dataset on Github shortly."
    expect(Dataset.count).to be before_datasets + 1
    expect(Dataset.last.name).to eq "#{common_name}-name"
    expect(Dataset.last.github_private?).to be true
  end

  def complete_form(page, common_name, data_file, owner = nil, licence = nil)
    dataset_name = "#{common_name}-name"
    fill_in 'dataset[name]', with: dataset_name
    fill_in 'dataset[description]', with: "#{common_name}-description"
    fill_in 'dataset[publisher_name]', with: "#{common_name}-publisher-name"
    fill_in 'dataset[publisher_url]', with: "http://#{common_name}-publisher-url.example.com/"
    fill_in 'files[][title]', with: "#{common_name}-file-name"
    fill_in 'files[][description]', with: "#{common_name}-file-description"
    choose('_publishing_method_github_private')
    attach_file("[files[][file]]", data_file)
    expect(page).to have_selector("input[value='#{dataset_name}']")
  end
end
