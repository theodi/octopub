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

  before(:each) do
    @user = create(:user, name: "User McUser", email: "user@user.com")
    OmniAuth.config.mock_auth[:github]
    sign_in @user
    allow_any_instance_of(User).to receive(:organizations) { organizations }
    allow_any_instance_of(User).to receive(:github_user) { github_user }
  end

  scenario "logged in visitors can access add dataset page" do
    visit root_path
    click_link "Add dataset"
    expect(page).to have_content "Dataset name"
    within 'form' do
      expect(page).to have_content "user-mcuser"
      expect(page).to have_content "Upload a schema for this Data File"
    end
  end

  context "visitor has schemas and" do

    before(:each) do
      good_schema_url = url_with_stubbed_get_for(File.join(Rails.root, 'spec', 'fixtures', 'schemas/good-schema.json'))
      create(:dataset_file_schema, url_in_repo: good_schema_url, name: 'good schema', description: 'good schema description', user: @user)
    end

    scenario "logged in visitors can access their own added schemas" do
      visit root_path
      click_link "Add dataset"
      expect(DatasetFileSchema.count).to be 1
      expect(page).to have_content "Dataset name"
      within 'form' do
        expect(page).to have_content "good schema"
        expect(page).to have_content "Or upload a new one"
        expect(page).to have_content "No schema required"
      end
    end
  end
end

