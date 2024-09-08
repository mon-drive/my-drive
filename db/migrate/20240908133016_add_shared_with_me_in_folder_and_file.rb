class AddSharedWithMeInFolderAndFile < ActiveRecord::Migration[6.1]
  def change
    add_column :user_folders, :sharedWithMe, :boolean, default: false
    add_column :user_files, :sharedWithMe, :boolean, default: false
  end
end
