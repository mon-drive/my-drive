class AddUniqueIndexToHasParents < ActiveRecord::Migration[6.1]
  def change
    add_index :has_parents, [:item_id, :parent_id, :item_type], unique: true, name: 'index_has_parents_on_item_and_parent_and_type'
  end
end
