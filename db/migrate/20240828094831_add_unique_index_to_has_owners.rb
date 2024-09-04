class AddUniqueIndexToHasOwners < ActiveRecord::Migration[6.1]
  def change
    add_index :has_owners, [:item, :owner_id], unique: true
  end
end
