class AddUniqueIndexToPermissionAndHasPermission < ActiveRecord::Migration[6.1]
  def change
    # Remove the existing index
    remove_index :permissions, name: "index_permissions_on_permission_id"

    # Add a new unique index
    add_index :permissions, :permission_id, unique: true, name: "index_permissions_on_permission_id"

    add_index :has_permissions, [:item_id, :permission_id, :item_type], unique: true
  end
end
