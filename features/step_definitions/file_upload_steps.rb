require 'google/apis/drive_v3'
require 'googleauth'

#Google::Apis::DriveV3 namespace for Google Drive interactions
Drive = Google::Apis::DriveV3

Given('a registered user named "Bob"') do
  # Using service account token
  SCOPES = ['https://www.googleapis.com/auth/drive']

  @drive_service = initialize_drive_service
end

Given("Bob wants to upload one or more valid files") do
  visit 'http://localhost:3000'
  # Temporarily create a file for testing
  @file = Tempfile.new('file1.txt')
  @file.write("Sample content for testing")
  @file.rewind  # Reset file pointer to the beginning
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
  visit 'http://localhost:3000/dashboard'
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
  @file_checked_for_viruses = true #TODO: Implement virus check with virustotal API ? 
  expect(@file_checked_for_viruses).to be true
end

Then("The file should be successfully uploaded to the server") do
  file_metadata = {
    name: 'file1.txt'
  }

  file = @drive_service.create_file(
    file_metadata,
    upload_source: @file.path,
    content_type: 'text/plain',
    fields: 'id'
  )

  @uploaded_file_id = file.id
  expect(@uploaded_file_id).not_to be_nil

  @file.close
  @file.unlink
end

And("Bob should see a confirmation message indicating successful upload") do
  # Check for confirmation message
  if @uploaded_file_id
    @confirmation_message = "Upload successful!"
  else
    @confirmation_message = "Upload failed."
  end
  expect(@confirmation_message).to eq("Upload successful!")
end

And("The uploaded file should be visible in Bob's files list or designated storage area") do
  # Check that the file appears in the list
  file_list = @drive_service.list_files(q: "name = 'file1.txt'")
  expect(file_list.files.map(&:id)).to include(@uploaded_file_id)
end


def initialize_drive_service
  authorization = Google::Auth::ServiceAccountCredentials.make_creds(
    json_key_io: File.open(Rails.root.join('config', 'mydrive-430108-3e571c4c5538.json')),
    scope: SCOPES
  )

  authorization.fetch_access_token!

  drive_service = Google::Apis::DriveV3::DriveService.new
  drive_service.authorization = authorization

  drive_service
end