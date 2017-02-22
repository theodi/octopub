require "rails_helper"

feature "Devise Logged in access to pages", type: :feature do

  before(:each) do
    @user = create(:user)
    visit root_path
    devise_login_as @user
    visit root_path
  end

  scenario "logged in visitors can access the home page and datasets" do
    create(:dataset, user: @user, url: 'https://meow.com', name: 'Woof', owner_avatar: 'https://meow.com')
    expect(page).to have_content "Signed in as #{@user.name}"
    click_link "All datasets"
    expect(page).to have_content "Woof"
  end

  scenario "logged in visitors can view their dataset file schemas (or see there are none)" do
    create(:dataset, user: @user, url: 'https://meow.com', name: 'Woof', owner_avatar: 'https://meow.com')
    click_link "List my dataset file schemas"
    expect(page).to have_content "You currently have no dataset file schemas"
  end

  scenario "logged in visitors can view their dataset file schemas" do
    schema_name = 'Good schema name'
    schema_description = 'Good schema description superduper'

    good_schema_url = url_with_stubbed_get_for(File.join(Rails.root, 'spec', 'fixtures', 'schemas/good-schema.json'))
    DatasetFileSchemaService.new.create_dataset_file_schema(schema_name, schema_description, good_schema_url, @user)

    click_link "List my dataset file schemas"
    expect(page).to have_content schema_name
    expect(page).to have_content schema_description
  end

  scenario "logged in visitors cannot view other users dataset file schemas" do

    other_user = create(:user, name: "Woof McUser", email: "woof@user.com")

    schema_name = 'Good schema name'
    schema_description = 'Good schema description superduper'

    good_schema_url = url_with_stubbed_get_for(File.join(Rails.root, 'spec', 'fixtures', 'schemas/good-schema.json'))
    create(:dataset_file_schema, url_in_repo: good_schema_url, name: schema_name, description: schema_description, user: other_user)

    click_link "List my dataset file schemas"
    expect(page).to have_content "You currently have no dataset file schemas"
  end
end

