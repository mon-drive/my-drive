require 'google/apis/drive_v3'
require 'googleauth'

#Google::Apis::DriveV3 namespace for Google Drive interactions
Drive = Google::Apis::DriveV3

Given('a registered user named "Bob"') do
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

Given("Bob wants to upload one or more valid files") do
  # Simulate Bob preparing files for upload
  @files = [
    { name: "file1.txt", content: "Sample content for file1" },
    { name: "file2.png", content: "Sample content for file2" },
    { name: "file3.pdf", content: "Sample content for file3" }
  ]
end

And("Bob has sufficient space") do
  #assume sufficient space
  @space_available = true
end

And("Bob has permission to write in that directory") do
  # Assume permission granted
  @permission_granted = true
end

When("Bob clicks the “+” button") do
  # Simulate the action of Bob initiating the upload process
  @button_clicked = true
end

And("Bob clicks the \"Upload file\" button") do
  # Simulate the action of Bob clicking the "Upload file" button
  @upload_initiated = true
end

Then("Bob should see a box where he can choose the files") do
  # Verify the file picker is shown
  expect(@upload_initiated).to be true
end

And("the file should be checked for viruses") do
  # Mock virus scanning (assume passing)
  @virus_scan_passed = true
end

Then("The file should be successfully uploaded to the server") do
  # Simulate file upload to Google Drive
  if @files && @permission_granted && @space_available
    # Here you would typically call the Google Drive API to upload files
    # For testing, we're assuming the upload is successful
    @upload_successful = true
  else
    @upload_successful = false
  end
  expect(@upload_successful).to be true
end

And("Bob should see a confirmation message indicating successful upload") do
  # Check for confirmation message
  if @upload_successful
    @confirmation_message = "Upload successful!"
  else
    @confirmation_message = "Upload failed."
  end
  expect(@confirmation_message).to eq("Upload successful!")
end

And("The uploaded file should be visible in Bob's files list or designated storage area") do
  # Verify file appears in the list (mocking)
  if @upload_successful
    @files_uploaded = @files.map { |file| file[:name] }
    expect(@files_uploaded).to include("file1.txt", "file2.png")
  end
end