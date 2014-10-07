@omniauth @vcr
Feature: Upload data to Github

  Scenario: Create new repo without data
    Given I am signed into Github
    When I go to the add new dataset page
    And I add my dataset details
    Then a new Github repo should be created
    When I click submit
    And the repo details should be stored in the database
    And my repo should be listed in the datasets index
