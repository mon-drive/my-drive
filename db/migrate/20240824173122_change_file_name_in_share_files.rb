class ChangeFileNameInShareFiles < ActiveRecord::Migration[6.1]
  def change
    add_foreign_key :share_files, :user_files
  end
end
