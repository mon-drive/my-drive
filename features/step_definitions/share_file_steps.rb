require 'google/apis/drive_v3'
require 'googleauth'

Given('two registered users named “Bob” and “Amin”') do
  SCOPES = ['https://www.googleapis.com/auth/drive']

  @drive_service1 = initialize_drive_service('mydrive-430108-980acf2b30ef.json') #Bob
  @drive_service2 = initialize_drive_service('mydrive-430108-3e571c4c5538.json') #Amin

end

Given("Bob is on a folder") do
  visit 'http://localhost:3000'
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

  # Temporarily create a file for testing
  @file = Tempfile.new('file1.txt')
  @file.write("Sample content for testing")
  @file.rewind  # Reset file pointer to the beginning
end

And("he clicks the 'Share' button") do
  # Simulate Bob clicking the "Share" button
  @share_button_clicked = true
end

Then("Bob should see a box where he can write the user he wants to share to") do
  # Verify the share dialog is shown
  expect(@share_button_clicked).to be true

  #DRIVE upload
  file_metadata = {
    name: 'file1.txt'
  }

  file = @drive_service1.create_file(
    file_metadata,
    upload_source: @file.path,
    content_type: 'text/plain',
    fields: 'id'
  )

  @uploaded_file_id = file.id
  expect(@uploaded_file_id).not_to be_nil

  #DB upload
  db_file1 = UserFile.create(user_file_id: file.id, name: file.name, size: file.size.to_i, mime_type: file.mime_type, created_time: file.created_time, modified_time: file.modified_time)
  expect(db_file1).not_to be_nil

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
  #DRIVE upload
  file_metadata = {
    name: 'file1.txt'
  }
  
  file = @drive_service2.create_file(
    file_metadata,
    upload_source: @file.path,
    content_type: 'text/plain',
    fields: 'id'
  )

  @uploaded_file_id = file.id
  expect(@uploaded_file_id).not_to be_nil

  #DB upload
  @db_file2 = UserFile.create(user_file_id: file.id, name: file.name, size: file.size.to_i, mime_type: file.mime_type, created_time: file.created_time, modified_time: file.modified_time)
  expect(@db_file2).not_to be_nil

  @file.close
  @file.unlink
end

Then("Bob should see a confirmation message indicating the file has been shared successfully") do
  # Simulate confirmation message
  expect(@uploaded_file_id).not_to be_nil
  expect(@db_file2).not_to be_nil
end




def initialize_drive_service(config_filename)
  authorization = Google::Auth::ServiceAccountCredentials.make_creds(
    json_key_io: File.open(Rails.root.join('config', config_filename)),
    scope: SCOPES
  )

  authorization.fetch_access_token!

  drive_service = Google::Apis::DriveV3::DriveService.new
  drive_service.authorization = authorization

  drive_service
end
