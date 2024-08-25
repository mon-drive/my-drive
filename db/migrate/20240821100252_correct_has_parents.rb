class CorrectHasParents < ActiveRecord::Migration[6.1]
  def change

    # Rimuovere la colonna errata se esiste
    remove_column :has_parents, :item, :string
  end
end
