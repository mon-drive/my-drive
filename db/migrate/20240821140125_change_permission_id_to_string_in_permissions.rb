class ChangePermissionIdToStringInPermissions < ActiveRecord::Migration[6.1]
  def change
    change_column :permissions, :permission_id, :string
  end
end
