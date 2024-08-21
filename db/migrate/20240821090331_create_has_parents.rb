class CreateHasParents < ActiveRecord::Migration[6.1]
  def change
    create_table :has_parents do |t|
      t.references :parent, foreign_key: true
      t.references :item, polymorphic: true, null: false

      t.timestamps
    end
  end
end
