class CreateFolders < ActiveRecord::Migration[6.1]
  def change
    create_table :folders do |t|

      t.string :folder_id
      t.string :name
      t.string :mime_type
      t.integer :size
      t.array :owners
      t.datetime :created_time
      t.datetime :modified_time
      t.string :permissions
      t.boolean :shared

      t.timestamps
    end
  end
end
