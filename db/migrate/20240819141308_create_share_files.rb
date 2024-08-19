class CreateShareFiles < ActiveRecord::Migration[6.1]
  def change
    create_table :share_files do |t|
      t.references :user, foreign_key: true
      t.references :file, foreign_key: true

      t.timestamps
    end
  end
end
