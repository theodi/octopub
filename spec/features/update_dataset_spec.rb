require "rails_helper"
require 'features/user_and_organisations'

feature "Update dataset page", type: :feature, vcr: { :match_requests_on => [:host, :method] } do
  include_context 'user and organisations'

  let(:data_file) { get_fixture_file('valid-schema.csv') }

  before(:each) do
    Dataset.set_callback(:update, :after, :create_repo_and_populate)
    skip_callback_if_exists(Dataset, :create, :after, :create_repo_and_populate)
    visit root_path
  end

  after(:each) do
    skip_callback_if_exists(Dataset, :update, :after, :create_repo_and_populate)
  end

  context "logged in visitor has schemas and" do

    before(:each) do
      expect(Dataset.count).to be 0
      good_schema_url = url_with_stubbed_get_for_fixture_file('schemas/good-schema.json')
      @dataset = create(:dataset_with_files, user: @user)
      expect(Dataset.count).to be 1
      allow_any_instance_of(Dataset).to receive(:owner_avatar) { "http://example.org/avatar.png" }

      click_link "List my datasets"
      expect(page).to have_content "My Datasets"
      expect(page.all('table.table tr').count).to be Dataset.count + 1
      page.find("tr[data-dataset-id='#{@dataset.id}']").click_link('Edit')
    end

    scenario "can access add dataset page" do
      expect(page).to have_content "Edit Dataset"
      new_description = Faker::Lorem.sentence
      fill_in 'dataset[description]', with: new_description

      # Bypass sidekiq completely
      allow(UpdateDataset).to receive(:perform_async) do |a,b,c,d,e|
         UpdateDataset.new.perform(a,b,c,d,e)
       end
      allow_any_instance_of(UpdateDataset).to receive(:handle_files) do |a,b|
        {}
      end
      allow_any_instance_of(Dataset).to receive(:create_repo_and_populate)
      allow_any_instance_of(Dataset).to receive(:fetch_repo)
      click_on 'Submit'

      @dataset.reload
      expect(page).to have_content ('Your edits have been queued for creation, and your edits should appear on Github shortly.')
      expect(Dataset.count).to be 1
      expect(@dataset.description).to eq new_description
    end
  end
end
