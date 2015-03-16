@omniauth @vcr
Feature: Upload data to Github

  Scenario: Create new repo without data
    Given I am signed into Github
    When I go to the add new dataset page
    And I add my dataset details
    And I don't specify any files
    And I click submit
    Then I should see "You must specify at least one dataset"

  Scenario: Create new repo with a dataset
    Given I am signed into Github
    When I go to the add new dataset page
    And I add my dataset details
    And I specify a file
    Then a new Github repo should be created
    And my dataset should get added to my repo
    And my dataset should have a HTML view attached
    When I click submit
    And the repo details should be stored in the database

  @javascript
  Scenario: Create new repo with multiple datasets
    Given I am signed into Github
    When I go to the add new dataset page
    And I add my dataset details
    And I specify 5 files
    Then a new Github repo should be created
    When I click submit
    And my 5 datasets should have been added to my repo
    And the repo details should be stored in the database
