@dashboard
Feature: Project Shortcuts
  Background:
    Given I sign in as a user
    And I own a project
    And I visit my project's commits page

  @javascript
  Scenario: Navigate to files tab
    Given I press "g" and "f"
    Then the active main tab should be Repository
    Then the active sub tab should be Files

  @javascript
  Scenario: Navigate to commits tab
    Given I visit my project's files page
    Given I press "g" and "c"
    Then the active main tab should be Repository
    Then the active sub tab should be Commits

  @javascript
  Scenario: Navigate to network tab
    Given I press "g" and "n"
    Then the active sub tab should be Network
    And the active main tab should be Repository

  @javascript
  Scenario: Navigate to repository charts tab
    Given I press "g" and "g"
    Then the active sub tab should be Charts
    And the active main tab should be Repository

  @javascript
  Scenario: Navigate to issues tab
    Given I press "g" and "i"
    Then the active main tab should be Issues

  @javascript
  Scenario: Navigate to merge requests tab
    Given I press "g" and "m"
    Then the active main tab should be Merge Requests

  @javascript
  Scenario: Navigate to snippets tab
    Given I press "g" and "s"
    Then the active main tab should be Snippets

  @javascript
  Scenario: Navigate to wiki tab
    Given I press "g" and "w"
    Then the active main tab should be Wiki

  @javascript
  Scenario: Navigate to project home
    Given I press "g" and "p"
<<<<<<< HEAD
    Then the active main tab should be Home
=======
    Then the active sub tab should be Home
    And the active main tab should be Project
>>>>>>> 6506645... Update tests for shortcuts and layout

  @javascript
  Scenario: Navigate to project feed
    Given I press "g" and "e"
<<<<<<< HEAD
    Then the active main tab should be Activity
=======
    Then the active sub tab should be Activity
    And the active main tab should be Project
>>>>>>> 6506645... Update tests for shortcuts and layout
