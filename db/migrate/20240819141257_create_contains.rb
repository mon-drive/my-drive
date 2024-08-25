class CreateContains < ActiveRecord::Migration[6.1]
  def change
    create_table :contains do |t|
      t.references :user_folder, foreign_key: true
      t.references :user_file, foreign_key: true

      t.timestamps
    end
  end
end
