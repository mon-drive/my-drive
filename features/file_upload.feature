Feature: File Upload
  As a registered user
  So that I can store and manage my files
  I want to upload files to myDrive

  Background:
    Given a registered user named "Bob"

  Scenario: Upload a valid file (Happy path)
    Given Bob wants to upload one or more valid files 
    And Bob has sufficient space
    And Bob has permission to write in that directory
    When Bob clicks the “+” button
    And Bob clicks the "Upload file" button
    Then Bob should see a box where he can choose the files
    And the file should be checked for viruses
    Then The file should be successfully uploaded to the server
    And Bob should see a confirmation message indicating successful upload
    And The uploaded file should be visible in Bob's files list or designated storage area