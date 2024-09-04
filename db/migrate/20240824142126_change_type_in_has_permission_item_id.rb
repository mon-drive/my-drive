class ChangeTypeInHasPermissionItemId < ActiveRecord::Migration[6.1]
  def change
    change_column :has_permissions, :item_id, :string
    remove_column :has_permissions, :item
  end
end
