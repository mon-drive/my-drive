class CreatePossesses < ActiveRecord::Migration[6.1]
  def change
    create_table :possesses do |t|
      t.references :user, foreign_key: true
      t.references :folder, foreign_key: true

      t.timestamps
    end
  end
end
