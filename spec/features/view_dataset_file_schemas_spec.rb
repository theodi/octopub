require "rails_helper"

feature "As a logged in user, viewing dataset file schemas", type: :feature do

  let(:schema_name) { Faker::Lorem.word }
  let(:schema_description) { Faker::Lorem.sentence }
  let(:good_schema_url) { url_with_stubbed_get_for_fixture_file('schemas/good-schema.json') }

  before(:each) do
    @user = create(:user, name: "Frank O'Ryan")
    OmniAuth.config.mock_auth[:github]
    visit root_path
    sign_in @user
  end

  context "with an existing schema" do
    before(:each) do
      DatasetFileSchemaService.new(schema_name, schema_description, good_schema_url, @user).create_dataset_file_schema
      visit root_path
    end

    scenario "list of my own schemas" do
      click_link "List my dataset file schemas"
      expect(page).to have_content schema_name
    end

    scenario "view a single schema" do
      click_link "List my dataset file schemas"
      expect(page).to have_content schema_name
      click_link schema_name
      expect(page).to have_content schema_name
    end
  end

  scenario "cannot view other user's schemas" do

    other_user = create(:user, name: "Woof McUser", email: "woof@user.com")
    create(:dataset_file_schema, url_in_repo: good_schema_url, name: schema_name, description: schema_description, user: other_user)
    visit root_path

    click_link "List my dataset file schemas"
    expect(page).to have_content "You currently have no dataset file schemas"
  end
end
