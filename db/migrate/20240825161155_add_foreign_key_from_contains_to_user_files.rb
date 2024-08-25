class AddForeignKeyFromContainsToUserFiles < ActiveRecord::Migration[6.1]
  def change
    add_foreign_key :contains, :user_files
  end
end
