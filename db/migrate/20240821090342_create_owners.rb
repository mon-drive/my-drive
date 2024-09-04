class CreateOwners < ActiveRecord::Migration[6.1]
  def change
    create_table :owners do |t|
      t.string :displayName
      t.string :emailAddress

      t.timestamps
    end
  end
end
