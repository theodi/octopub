require "rails_helper"

feature "Logged in access to pages for restricted publishers", type: :feature do

  let(:admin) { create(:admin) }
  let(:dataset_file_schema) { create(:dataset_file_schema, user: admin) }
  let(:user) { create(:user, restricted: true) }

  before(:each) do
    OmniAuth.config.mock_auth[:github]
    visit root_path
    sign_in user
  end

  context "with dataset already" do
    before(:each) do
      create(:dataset, user: user, url: 'https://meow.com', name: 'Woof', owner_avatar: 'https://meow.com')
      visit root_path
    end

    scenario "logged in publishers can view their public data" do
      expect(CGI.unescapeHTML(page.html)).to have_content "Signed in as #{user.name}"
      click_link "All datasets"
      expect(page).to have_content "Woof"
    end

    scenario "logged in publishers can view their dataset file schemas (or see there are none)" do
      click_link "List my dataset file schemas"
      expect(page).to have_content "You currently have no dataset file schemas"
    end

    scenario "logged in publishers cannot view user list" do
      expect(page).to_not have_content "Users"
      visit users_path
      expect(page).to have_content "You do not have permission to view that page or resource"
    end

    scenario "logged in publishers cannot edit other users" do
      other_user = create(:user)
      visit edit_user_path(other_user)
      expect(page).to have_content user.name
      expect(page).to_not have_content other_user.name
    end

    scenario "logged in publishers cannot edit other restricted users" do
      @other_user = create(:user)
      visit edit_restricted_user_path(@other_user)
      expect(page).to have_content "You do not have permission to view that page or resource"
    end
  end
end

