require "rails_helper"

feature "Logged in admin can edit user", type: :feature do
  include_context 'user and organisations'

  before(:each) do
    @admin = create(:admin)
    @publisher = create(:user, :with_twitter_name)
    OmniAuth.config.mock_auth[:github]
    sign_in @admin
    visit user_path(@publisher)
  end

  scenario "logged in admins can edit user details" do
    expect(page).to have_content "User Details"
    expect(page).to have_content @publisher.name
    click_on 'Edit user and allocate schemas'
    expect(page).to have_content "Edit user and allocate schemas"
    expect(page).to have_content @publisher.name

    expect(find_field('user[twitter_handle]').value).to eq @publisher.twitter_handle

    new_twitter_handle = Faker::Twitter.user[:screen_name]
    fill_in 'user[twitter_handle]', with: new_twitter_handle
    click_on 'Update'
    @publisher.reload
    expect(@publisher.twitter_handle).to eq new_twitter_handle
  end
end

