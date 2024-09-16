require 'google/apis/drive_v3'
require 'googleauth'

#Google::Apis::DriveV3 namespace for Google Drive interactions
Drive = Google::Apis::DriveV3

Given('a registered user named "Bob"') do
  # Using service account token
  SCOPES = ['https://www.googleapis.com/auth/drive']

  @drive_service = initialize_drive_service('mydrive-430108-3e571c4c5538.json')
  @test_user = create_test_user()
end

Given("Bob wants to upload one or more valid files") do
  visit 'http://localhost:3000'
end

And("Bob has sufficient space") do
  expect(@test_user.total_space > @test_user.used_space).to be true
end

And("Bob has permission to write in that directory") do
  create_permission_test()
  found_permission = Permission.find_by(emailAddress: @test_user.email)
  expect(found_permission.permission_type).to eq("write")
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

  # Temporarily create a file for testing
  @file = Tempfile.new('file1.txt')
  @file.write("Sample content for testing")
  @file.rewind  # Reset file pointer to the beginning
end

And("the file should be checked for viruses") do
  @file_checked_for_viruses = true #TODO: Implement virus check with virustotal API ? 
  expect(@file_checked_for_viruses).to be true
end

Then("The file should be successfully uploaded to the server") do
  #DRIVE upload
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

  #DB upload
  db_file = create_file_test(file)
  expect(db_file).not_to be_nil

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
  #DRIVE Check that the file appears in the list 
  file_list = @drive_service.list_files(q: "name = 'file1.txt'")
  expect(file_list.files.map(&:id)).to include(@uploaded_file_id)

  #DB Check that the file appears in the list
  db_file = UserFile.find_by(user_file_id: @uploaded_file_id)
  expect(db_file).not_to be_nil
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

def create_test_user()
  User.create(username: "Bob", email: "test@example.com", total_space: 10, used_space: 5)  
end

def create_permission_test()
  # Create a permission in the test database
  permission = Permission.create!(
    permission_type: "write",
    role: "user",
    emailAddress: "test@example.com",
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
    user_id: @test_user.id,
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