require "rails_helper"

feature "As a logged in user, viewing dataset files", type: :feature do
  include_context 'user and organisations'

  let(:schema_name) { Faker::Lorem.word }
  let(:schema_description) { Faker::Lorem.sentence }
  let(:download_url) { Faker::Internet.url }
  let(:good_schema_url) { url_with_stubbed_get_for_fixture_file('schemas/good-schema.json') }
  let(:filename) { 'test-data.csv' }
  let(:storage_key) { filename }
  let(:string_io_for_data_file) { get_string_io_from_fixture_file(filename) }
  let(:publisher) { create(:user) }
  let(:random_publisher) { create(:user) }
  let(:admin) { create(:user, role: :admin) }

  before(:each) do
    OmniAuth.config.mock_auth[:github]
    @dataset_file = create(:dataset_file, filename: filename, file: string_io_for_data_file, storage_key: storage_key)
    @dataset = create(:dataset, user: publisher, dataset_files: [ @dataset_file ], publishing_method: :local_private)
    allow(FileStorageService).to receive(:get_temporary_download_url).with(storage_key) { download_url }
  end

  after(:each) do
    sign_out
  end

  context 'as the creator' do
    before(:each) do
      sign_in publisher
    end

    it 'can view dataset files' do
      visit dashboard_path
      click_on(@dataset.name)
      expect(page).to have_content "#{@dataset.name}"
    end
  end

  it "cannot view other user's files" do
    sign_in random_publisher
    visit files_path(@dataset)
    expect(page).to have_content "You do not have permission"
  end

  it "cannot view other user's files unless you're an admin" do
    sign_in admin
    visit files_path(@dataset)
    expect(page).to have_content "#{@dataset.name}"
  end
end
