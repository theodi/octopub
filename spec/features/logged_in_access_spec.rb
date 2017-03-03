require "rails_helper"

feature "Logged in access to pages", type: :feature do

  before(:each) do
    @user = create(:user, name: "Frank O'Ryan")
  end

  scenario "logged in visitors can access the home page and datasets" do

    OmniAuth.config.mock_auth[:github]
    create(:dataset, user: @user, url: 'https://meow.com', name: 'Woof', owner_avatar: 'https://meow.com')

    visit root_path
    sign_in @user
    visit root_path

    expect(CGI.unescapeHTML(page.html)).to have_content "Signed in as #{@user.name}"
    click_link "All datasets"
    expect(page).to have_content "Woof"
  end

  scenario "logged in visitors can view their dataset file schemas (or see there are none)" do

    OmniAuth.config.mock_auth[:github]
    create(:dataset, user: @user, url: 'https://meow.com', name: 'Woof', owner_avatar: 'https://meow.com')

    visit root_path
    sign_in @user
    visit root_path

    click_link "List my dataset file schemas"
    expect(page).to have_content "You currently have no dataset file schemas"
  end

  scenario "logged in visitors can view their dataset file schemas" do

    OmniAuth.config.mock_auth[:github]

    schema_name = 'Good schema name'
    schema_description = 'Good schema description superduper'

    good_schema_url = url_with_stubbed_get_for(File.join(Rails.root, 'spec', 'fixtures', 'schemas/good-schema.json'))
   # create(:dataset_file_schema, url_in_repo: good_schema_url, name: schema_name, description: schema_description, user: @user)

    DatasetFileSchemaService.new(schema_name, schema_description, good_schema_url, @user).create_dataset_file_schema


    visit root_path
    sign_in @user
    visit root_path

    click_link "List my dataset file schemas"
    expect(page).to have_content schema_name
    expect(page).to have_content schema_description
  end

  scenario "logged in visitors cannot view other users dataset file schemas" do

    OmniAuth.config.mock_auth[:github]

    other_user = create(:user, name: "Woof McUser", email: "woof@user.com")

    schema_name = 'Good schema name'
    schema_description = 'Good schema description superduper'

    good_schema_url = url_with_stubbed_get_for(File.join(Rails.root, 'spec', 'fixtures', 'schemas/good-schema.json'))
    create(:dataset_file_schema, url_in_repo: good_schema_url, name: schema_name, description: schema_description, user: other_user)

    visit root_path
    sign_in @user
    visit root_path

    click_link "List my dataset file schemas"
    expect(page).to have_content "You currently have no dataset file schemas"
  end
end

