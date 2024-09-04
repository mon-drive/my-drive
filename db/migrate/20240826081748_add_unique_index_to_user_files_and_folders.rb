class AddUniqueIndexToUserFilesAndFolders < ActiveRecord::Migration[6.1]
  def change
    add_index :user_files, :user_file_id, unique: true
    add_index :user_folders, :user_folder_id, unique: true
  end
end
