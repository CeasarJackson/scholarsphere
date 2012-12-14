Feature: Browse files 

  Scenario: Browse via Fixtures 
    Given I load scholarsphere fixtures
    When I go to the home page
    And I follow "more Keyword"
    And I follow "test"
    Then I should see "1 - 4 of 4"
    When I follow "Test Document PDF"
    Then I should see "Download"
    But I should not see "Edit"
    Given I am logged in as "archivist1"
    When I follow "more Keyword"
    And I follow "test"
    And I follow "Test Document PDF"
    And I should see "Edit"
