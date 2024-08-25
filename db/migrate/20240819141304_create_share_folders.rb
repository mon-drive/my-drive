class CreateShareFolders < ActiveRecord::Migration[6.1]
  def change
    create_table :share_folders do |t|
      t.references :user, foreign_key: true
      t.references :user_folder, foreign_key: true

      t.timestamps
    end
  end
end
