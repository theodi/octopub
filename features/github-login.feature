@omniauth
Feature: Login with Github

  Scenario: Sucessful login
    Given I have a Github account
    When I visit the homepage
    When I click on the login link
    Then I should see a message saying I have logged in successfully
    And a user should be created in the database
