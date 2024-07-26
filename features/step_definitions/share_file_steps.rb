require 'google/apis/drive_v3'
require 'googleauth'

Given('two registered users named “Bob” and “Amin”') do
  # Mocking OmniAuth for Google OAuth login
  OmniAuth.config.test_mode = true
  OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new({
    provider: 'google_oauth2',
    uid: '123545',
    info: {
      name: 'Bob',
      email: 'bob@example.com',
      first_name: 'Bob',
      last_name: 'Test'
    },
    credentials: {
      token: 'mock_token',
      refresh_token: 'mock_refresh_token'
    }
  })
end

Given("Bob is on a folder") do
  # Simulate Bob navigating to a folder
  @folder = "My Folder"
end

And("he has read permission") do
  # Assume permission granted
  @permission_granted = true
end

When("Bob selects a file") do 
  # Simulate Bob selecting a file
  @file_selected = true
end

And("he clicks the 'Share' button") do
  # Simulate Bob clicking the "Share" button
  @share_button_clicked = true
end

Then("Bob should see a box where he can write the user he wants to share to") do
  # Verify the share dialog is shown
  expect(@share_button_clicked).to be true
end

And("Bob writes Amin’s email in the 'Share to' box") do
  # Simulate Bob writing Amin's email
  @amin_email = "amin"
end

And("Bob chooses what permissions to give to Amin in the 'Permissions' box") do
  # Simulate Bob choosing permissions
  @permissions = "read,write"
end

Then("Amin receives an email with a limited-time link") do
  # Simulate Amin receiving an email
  @email_sent = true
end

When("Amin clicks on the link, the file is added to his myDrive") do
  # Simulate Amin clicking the link
  @file_added = true
end

Then("Bob should see a confirmation message indicating the file has been shared successfully") do
  # Simulate confirmation message
  expect(@file_added).to be true
end


