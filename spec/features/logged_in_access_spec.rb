require "rails_helper"

feature "Logged in access to pages", type: :feature do

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

    scenario "logged in visitors can access the home page and datasets" do
      expect(CGI.unescapeHTML(page.html)).to have_content "Signed in as #{@user.name}"
      click_link "All datasets"
      expect(page).to have_content "Woof"
    end

    scenario "logged in visitors can view their dataset file schemas (or see there are none)" do
      click_link "List my dataset file schemas"
      expect(page).to have_content "You currently have no dataset file schemas"
    end
  end
end

