class AddUniqueIndexToContains < ActiveRecord::Migration[6.1]
  def change
    add_index :contains, [:user_folder_id, :user_file_id], unique: true
  end
end
