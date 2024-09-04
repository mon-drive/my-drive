class AddUniqueIndexToOwners < ActiveRecord::Migration[6.1]
  def change
    add_index :owners, :emailAddress, unique: true
  end
end
