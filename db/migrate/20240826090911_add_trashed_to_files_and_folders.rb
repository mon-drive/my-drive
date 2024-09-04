class AddTrashedToFilesAndFolders < ActiveRecord::Migration[6.1]
  def change
    add_column :user_files, :trashed, :boolean, default: false
    add_column :user_folders, :trashed, :boolean, default: false
  end
end
