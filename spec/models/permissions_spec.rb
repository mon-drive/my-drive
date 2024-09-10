require 'rails_helper'

RSpec.describe Permission, type: :model do
  #uploading a file
  describe "#bob has permission to write in that directory" do
    it "returns true if the user has permission to write" do
      # Create a permission in the test database
      permission = Permission.create!(
        permission_type: "write",
        role: "user",
        emailAddress: "test@example.com",
        permission_id: "12345"
      )

      # Find the permission using the permission_id
      found_permission = Permission.find_by(permission_id: "12345")

      # Expect the found permission to match the created one
      expect(found_permission).to eq(permission)
      expect(found_permission.permission_type).to eq("write")
      expect(found_permission.role).to eq("user")
      expect(found_permission.emailAddress).to eq("test@example.com")
    end
    it "returns false if the user doesn't have permission to write" do
      # Create a permission in the test database
      permission = Permission.create!(
        permission_type: "read",
        role: "user",
        emailAddress: "test@example.com",
        permission_id: "12345"
      )

      # Find the permission using the permission_id
      found_permission = Permission.find_by(permission_id: "12345")

      # Expect the found permission to match the created one
      expect(found_permission).to eq(permission)
      expect(found_permission.permission_type).not_to eq("write")
      expect(found_permission.role).to eq("user")
      expect(found_permission.emailAddress).to eq("test@example.com")
    end
  end


  
  #sharing a file
  describe "#bob has permission to share the file" do
    it "returns true if the user has permission to share" do
      # Create a permission in the test database
      permission = Permission.create!(
        permission_type: "write",
        role: "user",
        emailAddress: "test@example.com",
        permission_id: "12345"
      )

      # Find the permission using the permission_id
      found_permission = Permission.find_by(permission_id: "12345")

      # Expect the found permission to match the created one
      expect(found_permission).to eq(permission)
      expect(found_permission.permission_type).to eq("write")
      expect(found_permission.role).to eq("user")
      expect(found_permission.emailAddress).to eq("test@example.com")
    end
    it "returns false if the user doesn't have permission to share" do
      # Create a permission in the test database
      permission = Permission.create!(
        permission_type: "read",
        role: "user",
        emailAddress: "test@example.com",
        permission_id: "12345"
      )

      # Find the permission using the permission_id
      found_permission = Permission.find_by(permission_id: "12345")

      # Expect the found permission to match the created one
      expect(found_permission).to eq(permission)
      expect(found_permission.permission_type).not_to eq("write")
      expect(found_permission.role).to eq("user")
      expect(found_permission.emailAddress).to eq("test@example.com")
    end
    it "returns true if the file is owned by the user" do
      # Create a permission in the test database
      permission = Permission.create!(
        permission_type: "write",
        role: "user",
        emailAddress: "test@example.com",
        permission_id: "12345"
      )

      # Find the permission using the permission_id
      found_permission = Permission.find_by(permission_id: "12345")

      # Expect the found permission to match the created one
      expect(found_permission).to eq(permission)
      expect(found_permission.permission_type).to eq("write")
      expect(found_permission.role).to eq("user")
      expect(found_permission.emailAddress).to eq("test@example.com")
    end
    it "returns false if the file isn't owned by the user" do
      # Create a permission in the test database
      permission = Permission.create!(
        permission_type: "write",
        role: "user",
        emailAddress: "other@example.com",
        permission_id: "12345"
      )

      # Find the permission using the permission_id
      found_permission = Permission.find_by(permission_id: "12345")

      # Expect the found permission to match the created one
      expect(found_permission).to eq(permission)
      expect(found_permission.permission_type).to eq("write")
      expect(found_permission.role).to eq("user")
      expect(found_permission.emailAddress).not_to eq("test@example.com")
    end
  end
end
