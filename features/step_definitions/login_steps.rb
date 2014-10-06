Given(/^I have a Github account$/) do
  @email = 'test@example.com'

  OmniAuth.config.mock_auth[:github] = {
      "provider"=>"github",
      "uid" => "123545",
      "info"=> {
                  "email"=> @email,
                  "name"=>"Test User"
               }
  }
end

When(/^I visit the homepage$/) do
  visit "/"
end

When(/^I click on the login link$/) do
  click_link 'Sign in with Github'
end

Then(/^I should see a message saying I have logged in successfully$/) do
  expect(page).to have_content 'Signed in!'
end

Then(/^a user should be created in the database$/) do
  expect(User.count).to eql(1)

  user = User.first

  expect(user.email).to eql(@email)
end
