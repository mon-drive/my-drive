class AddPermissionIdToPermissions < ActiveRecord::Migration[6.1]
  def change
    add_column :permissions, :permission_id, :bigint
    add_index :permissions, :permission_id

  end
end
