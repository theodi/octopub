@omniauth
Feature: Add a datapackage to the generated repo

  @javascript
  Scenario: Generate a datapackage.json
    Given I am signed into Github
    When I go to the add new dataset page
    And I add my dataset details
    And I specify 5 files
    And a datapackage.json should be generated
    And the datapackage.json should be added to my repo
    When I click submit
