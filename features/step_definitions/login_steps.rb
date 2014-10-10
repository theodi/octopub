Given(/^I have a Github account$/) do
  @email = 'test@example.com'
  @name = "Test User"
  @nickname = "test"
  @token = "abcd123r4feefdsfscas"

  OmniAuth.config.mock_auth[:github] = {
      "provider"=>"github",
      "uid" => "123545",
      "info"=> {
                  "nickname"=> @nickname,
                  "email"=> @email,
                  "name"=>@name,
                  "image"=>"https://avatars.githubusercontent.com/u/123545?v=2",
                  "urls" => {
                      "GitHub"=>"https://github.com/test",
                      "Blog"=>nil
                  }
               },
      "credentials" => {
                    "token" => @token,
                    "expires" => false
                  }
  }
end

When(/^I visit the homepage$/) do
  visit "/"
end

When(/^I click on the login link$/) do
  click_link 'Sign in with Github', match: :first
end

Then(/^I should see a message saying I have logged in successfully$/) do
  expect(page).to have_content 'Signed in!'
end

Then(/^I should see that I am signed in$/) do
  expect(page).to have_content "Signed in as #{@nickname}"
end

Then(/^a user should be created in the database$/) do
  expect(User.count).to eql(1)

  user = User.first

  expect(user.email).to eql(@email)
  expect(user.name).to eql(@nickname)
  expect(user.token).to eql(@token)
end

Given(/^I am signed into Github$/) do
  steps %Q{
    Given I have a Github account
    And I visit the homepage
    And I click on the login link
  }
  @user = User.find_by_email(@email)
end
