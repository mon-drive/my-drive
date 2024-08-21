class RenameTypeInPermissions < ActiveRecord::Migration[6.1]
  def change
    rename_column :permissions, :type, :permission_type
  end
end
