class ChangeUidToUsers < ActiveRecord::Migration[6.1]
  def change
    rename_column :users, :uid, :user_id
  end
end
