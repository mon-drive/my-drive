class CreatePermissions < ActiveRecord::Migration[6.1]
  def change
    create_table :permissions do |t|
      t.string :type
      t.string :role
      t.string :emailAddress

      t.timestamps
    end
  end
end
