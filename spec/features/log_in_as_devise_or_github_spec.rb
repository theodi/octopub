require "rails_helper"

feature "Log in as github or devise user", type: :feature do

  let(:devise_user_email) { 'devise@example.com' }
  let(:github_user_email) { 'github@example.com' }
  let(:devise_user_password) { 'devised' }

  before(:each) do
    @devise_user = create(:user, email: devise_user_email, password: devise_user_password)
    @github_user = create(:github_user, email: github_user_email)
    visit root_path
  end

  scenario "log in and out as devise user" do
    click_link "Register/sign in"
    expect(page).to have_content "Sign in"

    within 'form' do
      fill_in 'user_email', with: devise_user_email
      fill_in 'user_password', with: devise_user_password
      click_on 'Sign in'
    end
    expect(page).to have_content "Signed in as #{@devise_user.name}"
    click_link 'Logout'
    expect(page).to_not have_content "Signed in as #{@devise_user.name}"
    expect(page).to have_content "Sign in"
  end

  scenario "log in and out as github user" do
    OmniAuth.config.mock_auth[:github]

    sign_in @github_user
    visit root_path

    expect(page).to have_content "Signed in as #{@github_user.name}"

    # As sign in doesn't really sign in, it just stubs App controller
    sign_out
    click_link 'Logout'

    expect(page).to have_content "Signed out"
    expect(page).to_not have_content "Signed in as #{@github_user.name}"
    expect(page).to have_content "Sign in"
  end
end
