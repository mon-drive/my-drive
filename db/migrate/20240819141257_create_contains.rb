class CreateContains < ActiveRecord::Migration[6.1]
  def change
    create_table :contains do |t|
      t.references :folder, foreign_key: true
      t.references :file, foreign_key: true

      t.timestamps
    end
  end
end
