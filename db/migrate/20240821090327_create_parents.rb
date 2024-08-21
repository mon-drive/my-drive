class CreateParents < ActiveRecord::Migration[6.1]
  def change
    create_table :parents do |t|
      t.string :itemid
      t.integer :num

      t.timestamps
    end
  end

end
