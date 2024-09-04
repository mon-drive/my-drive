class CreateHasOwners < ActiveRecord::Migration[6.1]
  def change
    create_table :has_owners do |t|
      t.references :owner, foreign_key: true
      t.string :item # ID dell'elemento, che può essere un File o una Cartella

      t.timestamps
    end
  end
end
