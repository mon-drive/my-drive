class RemovePermissionInFolder < ActiveRecord::Migration[6.1]
  def change
    remove_column :folders, :permissions, :string
  end
end
