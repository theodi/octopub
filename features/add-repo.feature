@omniauth @vcr
Feature: Upload data to Github

  Scenario: Create new repo without data
    Given I am signed into Github
    When I go to the add new dataset page
    And I add my dataset details
    Then a new Github repo should be created
    When I click submit
    And I should see "Dataset created sucessfully"
    And the repo details should be stored in the database
    And my repo should be listed in the datasets index

  Scenario: Create new repo with a dataset
    Given I am signed into Github
    When I go to the add new dataset page
    And I add my dataset details
    And I specify a file
    Then a new Github repo should be created
    And my dataset should get added to my repo
    When I click submit
