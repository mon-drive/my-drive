class AddUniqueIndexToPossess < ActiveRecord::Migration[6.1]
  def change
    add_index :possesses, [:user_id, :user_folder_id], unique: true
  end
end
