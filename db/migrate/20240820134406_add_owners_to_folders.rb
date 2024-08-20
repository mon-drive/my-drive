class AddOwnersToFolders < ActiveRecord::Migration[6.1]
  def change
    add_column :folders, :owners, :array
  end
end
