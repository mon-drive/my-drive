class UpdateDatetimeUserFolderAndFiles < ActiveRecord::Migration[6.1]
  def change
    change_column :user_files, :created_at, :datetime, null: false, default: -> { "CURRENT_TIMESTAMP" }
    change_column :user_files, :updated_at, :datetime, null: false, default: -> { "CURRENT_TIMESTAMP" }

    change_column :user_folders, :created_at, :datetime, null: false, default: -> { "CURRENT_TIMESTAMP" }
    change_column :user_folders, :updated_at, :datetime, null: false, default: -> { "CURRENT_TIMESTAMP" }
  end
end
