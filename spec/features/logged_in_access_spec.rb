require "rails_helper"

feature "Logged in access to pages", type: :feature do

  before(:each) do
    @user = create(:user, name: "User McUser", email: "user@user.com")
  end

  scenario "logged in visitors can access the home page and datasets" do

    OmniAuth.config.mock_auth[:github]
    create(:dataset, user: @user, url: 'https://meow.com', name: 'Woof', owner_avatar: 'https://meow.com')

    visit root_path
    sign_in @user
    visit root_path

    expect(page).to have_content "Signed in as User McUser"
    click_link "All datasets"
    expect(page).to have_content "Woof"
  end
end

