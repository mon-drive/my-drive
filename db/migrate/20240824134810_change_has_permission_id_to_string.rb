class ChangeHasPermissionIdToString < ActiveRecord::Migration[6.1]
  def change
    change_column :has_permissions, :permission_id, :string
  end
end
