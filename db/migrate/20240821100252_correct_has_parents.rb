class CorrectHasParents < ActiveRecord::Migration[6.1]
  def change
    # Aggiungere le colonne per l'associazione polimorfica
    add_column :has_parents, :item_id, :integer, null: false
    add_column :has_parents, :item_type, :string, null: false

    # Rimuovere la colonna errata se esiste
    remove_column :has_parents, :item, :string
  end
end
