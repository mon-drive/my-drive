class AddFileExtensionToUserFile < ActiveRecord::Migration[6.1]
  def change
    add_column :user_files, :file_extension, :string
  end
end
