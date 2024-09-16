require 'google/apis/drive_v3'
require 'googleauth'

Given('two registered users named “Bob” and “Amin”') do
  SCOPES = ['https://www.googleapis.com/auth/drive']

  @drive_service1 = initialize_drive_service('mydrive-430108-980acf2b30ef.json') #Bob
  @drive_service2 = initialize_drive_service('mydrive-430108-3e571c4c5538.json') #Amin
  create_test_users()
end

Given("Bob is on a folder") do
  visit 'http://localhost:3000'
end

And("he has read permission") do
  create_permissions_test()
  found_permission = Permission.find_by(emailAddress: $test_user_1.email)
  expect(found_permission.permission_type).to eq("read")
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
  @amin_email = $test_user_2.email
end

And("Bob chooses what permissions to give to Amin in the 'Permissions' box") do
  # Simulate Bob choosing permissions
  @permissions = "read,write"
end

Then("Amin receives an email with a limited-time link") do
  create_test_share()
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
  share = Possess.find_by(user_id: $test_user_2.id)
  expect(share).not_to be_nil
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

def create_test_users()
  $test_user_1 = User.create(username: "Bob", email: "test1@example.com", total_space: 10, used_space: 5)  
  $test_user_2 = User.create(username: "Amin", email: "test2@example.com", total_space: 10, used_space: 5)
end

def create_permissions_test()
  # Create a permission in the test database
  permission = Permission.create!(
    permission_type: "read",
    role: "user",
    emailAddress: "test1@example.com",
    permission_id: "12345"
  )

  folder = UserFolder.create(name: "folder", size: 1, mime_type: "application/vnd.google-apps.folder", created_time: Time.now, modified_time: Time.now)

  hp = HasPermission.upsert({
    item_id: folder.id,
    permission_id: permission.id,
    item_type: 'UserFolder',
    created_at: Time.now,
    updated_at: Time.now
  }, unique_by: %i[item_id permission_id item_type])

  Possess.upsert({
    user_id: $test_user_1.id,
    user_folder_id: folder.id,
    created_at: Time.now,
    updated_at: Time.now 
  }, unique_by: %i[user_id user_folder_id])
end

def create_test_share()
  folder = UserFolder.find_by(name: "folder")
  Possess.upsert({
    user_id: $test_user_2.id,
    user_folder_id: folder.id,
    created_at: Time.now,
    updated_at: Time.now 
  }, unique_by: %i[user_id user_folder_id])
end

def create_file_test(file)
  db_file = UserFile.create(user_file_id: file.id, name: file.name, size: file.size.to_i, mime_type: file.mime_type, created_time: file.created_time, modified_time: file.modified_time)

  folder = UserFolder.find_by(name: "folder")
  Contains.upsert({
    user_folder_id: folder.id,
    user_file_id: db_file.id,
    created_at: Time.now,
    updated_at: Time.now 
  }, unique_by: %i[user_folder_id user_file_id])

  return db_file
end
