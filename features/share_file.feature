Feature: Share File
  As a Registered user
  So that I can share my files/folders
  I want to share my files/folders to other registered users

  Background:
    Given two registered users named “Bob” and “Amin”

  Scenario: Successfully share a file (Happy path)
    Given Bob is on a folder
    And he has read permission
    When Bob selects a file
    And he clicks the 'Share' button
    Then Bob should see a box where he can write the user he wants to share to
    And Bob writes Amin’s email in the 'Share to' box
    And Bob chooses what permissions to give to Amin in the 'Permissions' box
    Then Amin receives an email with a limited-time link
    When Amin clicks on the link, the file is added to his myDrive
    Then Bob should see a confirmation message indicating the file has been shared successfully