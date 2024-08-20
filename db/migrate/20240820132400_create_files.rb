class CreateFiles < ActiveRecord::Migration[6.1]
  def change
    create_table :files do |t|

      t.string :file_id
      t.string :name
      t.string :mime_type
      t.integer :size
      t.datetime :created_time
      t.datetime :modified_time
      t.string :permissions
      t.boolean :shared

      t.timestamps
    end
  end
end
