class RenameHasPermissionIdToString < ActiveRecord::Migration[6.1]
  def change
    rename_column :has_permissions, :permission_id, :permission
  end
end
