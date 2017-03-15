# require "rails_helper"

# feature "Logged in admin access to pages", type: :feature do

#   before(:each) do
#     @user = create(:admin, name: "Frank O'Ryan")
#     OmniAuth.config.mock_auth[:github]
#     visit root_path
#     sign_in @user
#   end

#   context "with dataset already" do
#     scenario "logged in publishers can view user list" do
#       expect(page).to have_content "Users"
#       visit users_path
#       expect(page).to have_content "Users"
#     end
#   end
# end





