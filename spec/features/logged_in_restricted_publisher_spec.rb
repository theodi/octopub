require "rails_helper"

feature "Logged in access to pages for restricted publishers", type: :feature do
  include_context 'user and organisations'

  let(:admin) { create(:admin) }
  let(:dataset_file_schema) { create(:dataset_file_schema, user: admin) }
  let(:user) { create(:user, restricted: true) }

  before(:each) do
    OmniAuth.config.mock_auth[:github]
    visit root_path
    sign_in user
    visit root_path
  end

  context "with public dataset already" do
    before(:each) do
      create(:dataset, user: user, url: 'https://meow.com', name: 'Woof', owner_avatar: 'https://meow.com')
      visit root_path
    end

    scenario "can view it in public list" do
      expect(CGI.unescapeHTML(page.html)).to have_content "Signed in as #{user.name}"
      click_link "Public datasets"
      expect(page).to have_content "Woof"
    end

    scenario "can view it in my datasets" do
      expect(CGI.unescapeHTML(page.html)).to have_content "Signed in as #{user.name}"
      click_link "My datasets"
      expect(page).to have_content "Woof"
    end
  end

  # scenario "can add a dataset with restricted schema" do
  #   click_link "List my dataset file schemas"
  #   expect(page).to have_content "You currently have no dataset file schemas"
  #   pending
  # end



end
