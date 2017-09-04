require "rails_helper"

feature "Allocated schemas", type: :feature do
  include_context 'user and organisations'

  before(:each) do
    @admin = create(:admin)
    @publisher = create(:user)
    OmniAuth.config.mock_auth[:github]
    sign_in @admin
  end

  context "can be viewed" do
    scenario "logged in admins can view" do
      dataset_file_schema = create(:dataset_file_schema, user: @admin)
      @publisher.allocated_dataset_file_schemas << dataset_file_schema
      visit user_path(@publisher)

      expect(page).to have_content "User Details"
      expect(page).to have_content @publisher.name
      expect(page).to_not have_content "User's Dataset File Schemas"
      expect(page).to have_content "Other Dataset File Schemas the User has been allocated"
      expect(page).to have_content dataset_file_schema.name
    end
  end
end

