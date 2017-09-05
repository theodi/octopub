require "rails_helper"

feature "Logged in access to pages", type: :feature do
  include_context 'user and organisations'

  before(:each) do
    @user = create(:user, name: "Frank O'Ryan")
    OmniAuth.config.mock_auth[:github]
    visit root_path
    sign_in @user
  end

  context "with dataset already" do
    before(:each) do
      create(:dataset, user: @user, url: 'https://meow.com', name: 'Woof', owner_avatar: 'https://meow.com')
      visit root_path
    end

    scenario "logged in publishers can access the home page and datasets" do
      expect(CGI.unescapeHTML(page.html)).to have_content "Signed in as #{@user.name}"
      click_link "Public datasets"
      expect(page).to have_content "Woof"
    end

    scenario "logged in publishers can view their dataset file schemas (or see there are none)" do
      click_link 'Dataset file schemas'
      expect(page).to have_content "You currently have no dataset file schemas"
    end

    scenario "logged in publishers cannot view user list" do
      expect(page).to_not have_content "Users"
      visit users_path
      expect(page).to have_content "You do not have permission to view that page or resource"
    end

    scenario "logged in publishers cannot edit other users" do
      @other_user = create(:user)
      visit edit_user_path(@other_user)
      expect(page).to have_content @user.name
      expect(page).to_not have_content @other_user.name
    end

    scenario "logged in publishers cannot edit other restricted users" do
      @other_user = create(:user)
      visit edit_restricted_user_path(@other_user)
      expect(page).to have_content "You do not have permission to view that page or resource"
    end
  end
end

