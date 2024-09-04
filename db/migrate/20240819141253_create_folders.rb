class CreateFolders < ActiveRecord::Migration[6.1]
  def change
    create_table :user_folders do |t|

      t.string :user_folder_id
      t.string :name
      t.string :mime_type
      t.integer :size
      t.datetime :created_time
      t.datetime :modified_time
      t.boolean :shared

      t.timestamps
    end
  end
end
