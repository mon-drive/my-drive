class AddPermissionIdToHasPermissions < ActiveRecord::Migration[6.1]
  def change
    add_column :has_permissions, :permission_id, :string
    remove_column :has_permissions, :permission, :string # Rimuove la vecchia colonna string
    add_foreign_key :has_permissions, :permissions
  end
end
