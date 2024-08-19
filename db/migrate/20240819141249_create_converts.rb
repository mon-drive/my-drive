class CreateConverts < ActiveRecord::Migration[6.1]
  def change
    create_table :converts do |t|
      t.references :file, foreign_key: true
      t.references :premium_user, foreign_key: { to_table: :users }

      t.timestamps
    end
  end
end
