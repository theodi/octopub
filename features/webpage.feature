@omniauth
Feature: Add an index.html to the generated repo

  @javascript
  Scenario: Generate an index.html
    Given I am signed into Github
    When I go to the add new dataset page
    And I add my dataset details
    And I specify 5 files
    Then the index.html should be added to my repo
    And the assets should be added to my repo
    When I click submit
