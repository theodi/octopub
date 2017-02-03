require "rails_helper"

feature "Add dataset page", type: :feature do

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
    end
  end
end
