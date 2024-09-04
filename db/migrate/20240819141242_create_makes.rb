class CreateMakes < ActiveRecord::Migration[6.1]
  def change
    create_table :makes do |t|
      t.references :user, foreign_key: true
      t.references :transaction, foreign_key: true

      t.timestamps
    end
  end
end
