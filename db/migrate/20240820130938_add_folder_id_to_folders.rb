class AddFolderIdToFolders < ActiveRecord::Migration[6.1]
  def change
    add_column :folders, :folder_id, :string
  end
end
