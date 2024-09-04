class AddUniqueToParentItemId < ActiveRecord::Migration[6.1]
  def change
    add_index :parents, :itemid, unique: true
  end
end
