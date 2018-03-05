require "rails_helper"
require 'features/user_and_organisations'
require 'support/odlifier_licence_mock'

feature "Publisher can create a non-GitHub private repo", type: :feature do
  include_context 'user and organisations'
  include_context 'odlifier licence mock'

  it "by uploading a simple dataset" do
    Sidekiq::Testing.inline!

    expect(RepoService).to_not receive(:create_repo)
    expect(RepoService).to_not receive(:fetch_repo)
    expect_any_instance_of(JekyllService).to_not receive(:create_data_files) { nil }
    expect_any_instance_of(JekyllService).to_not receive(:push_to_github) { nil }
    expect_any_instance_of(JekyllService).to_not receive(:create_public_views) { nil }
    expect_any_instance_of(DatasetMailer).to receive(:success)

    visit root_path
    click_link "Create a new data collection"
    data_file = get_fixture_file('valid-schema.csv')
    common_name = 'Fri1437'

    before_datasets = Dataset.count
    expect(page).to have_selector(:link_or_button, "Submit")
    within 'form' do
      expect(page).to have_content @user.github_username
      expect(page).to have_content "Upload a schema for this Data File"
      complete_form(page, common_name, data_file)
    end

    click_on 'Submit'

    expect(page).to have_content "Your dataset has been queued for creation and should be completed shortly."
    expect(Dataset.count).to be before_datasets + 1
    expect(Dataset.last.name).to eq "#{common_name}-name"
    expect(Dataset.last.local_private?).to be true

    Sidekiq::Testing.fake!
  end

  def complete_form(page, common_name, data_file, owner = nil, licence = nil)
    dataset_name = "#{common_name}-name"

    fill_in 'dataset[name]', with: dataset_name
    fill_in 'dataset[description]', with: "#{common_name}-description"
    fill_in 'dataset[publisher_name]', with: "#{common_name}-publisher-name"
    fill_in 'dataset[publisher_url]', with: "http://#{common_name}-publisher-url.example.com/"
    fill_in 'files[][title]', with: "#{common_name}-file-name"
    fill_in 'files[][description]', with: "#{common_name}-file-description"
    choose('_publishing_method_local_private')
    attach_file("[files[][file]]", data_file)
    expect(page).to have_selector("input[value='#{dataset_name}']")
  end
end
