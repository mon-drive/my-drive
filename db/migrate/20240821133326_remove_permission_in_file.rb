class RemovePermissionInFile < ActiveRecord::Migration[6.1]
  def change
    remove_column :files, :permissions, :string
  end
end
