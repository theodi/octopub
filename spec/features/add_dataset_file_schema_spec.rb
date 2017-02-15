require "rails_helper"

feature "Add dataset page", type: :feature, vcr: { :match_requests_on => [:host, :method] } do

  let(:organizations) {
    [
      OpenStruct.new(
        organization: OpenStruct.new({
          login: "org1",
          avatar_url: "http://www.example.org/avatar1.png"
        })
      ),
      OpenStruct.new(
        organization: OpenStruct.new({
          login: "org2",
          avatar_url: "http://www.example.org/avatar2.png"
        })
      ),
      OpenStruct.new(
        organization: OpenStruct.new({
          login: "org3",
          avatar_url: "http://www.example.org/avatar3.png"
        })
      )
    ]
  }

  let(:github_user) {
    OpenStruct.new(
      avatar_url: "http://www.example.org/avatar2.png"
    )
  }

  let(:data_file) {
    File.join(Rails.root, 'spec', 'fixtures', 'valid-schema.csv')
  }

  before(:each) do
    @user = create(:user, name: "User McUser", email: "user@user.com")
    OmniAuth.config.mock_auth[:github]
    sign_in @user
    allow_any_instance_of(User).to receive(:organizations) { organizations }
    allow_any_instance_of(User).to receive(:github_user) { github_user }
  end

  context "logged in visitors has no schemas" do
    scenario "and can add a dataset file schema on it's own" do

      visit root_path

      click_link "List my dataset file schemas"
      expect(page).to have_content "You currently have no dataset file schemas, why not add one?"

      
      # common_name = 'Fri1437'

      # before_datasets = Dataset.count
      # expect(page).to have_selector(:link_or_button, "Submit")
      # within 'form' do
      #   expect(page).to have_content "user-mcuser"
      #   expect(page).to have_content "Upload a schema for this Data File"
      #   complete_form(page, common_name, data_file)   
      # end

      # # Bypass sidekiq completely
      # allow(CreateDataset).to receive(:perform_async) do |a,b,c,d|
      #   CreateDataset.new.perform(a,b,c,d)
      # end

      # click_on 'Submit'

      # expect(page).to have_content "Your dataset has been queued for creation, and you should receive an email with a link to your dataset on Github shortly."
      # expect(Dataset.count).to be before_datasets + 1
      # expect(Dataset.last.name).to eq "#{common_name}-name"
    end

  end

  def complete_schema_form(page, common_name, data_file, owner = nil, licence = nil)

    # dataset_name = "#{common_name}-name"

    # fill_in 'dataset[name]', with: dataset_name
    # fill_in 'dataset[description]', with: "#{common_name}-description"
    # fill_in 'dataset[publisher_name]', with: "#{common_name}-publisher-name"
    # fill_in 'dataset[publisher_url]', with: "http://#{common_name}-publisher-url.example.com/"
    # fill_in 'files[][title]', with: "#{common_name}-file-name"
    # fill_in 'files[][description]', with: "#{common_name}-file-description"
    # attach_file("[files[][file]]", data_file)
    # expect(page).to have_selector("input[value='#{dataset_name}']")

  end
end

