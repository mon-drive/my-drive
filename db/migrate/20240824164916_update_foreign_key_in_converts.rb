class UpdateForeignKeyInConverts < ActiveRecord::Migration[6.1]
  def change
    # Aggiungi il nuovo riferimento
    add_foreign_key :converts, :user_files, column: :user_file_id
  end
end
