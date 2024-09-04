class CreateHasPermissions < ActiveRecord::Migration[6.1]
  def change
    create_table :has_permissions do |t|
      t.references :permission, foreign_key: { to_table: :permissions }, type: :bigint
      t.references :item, polymorphic: true

      t.timestamps
    end
  end
end
