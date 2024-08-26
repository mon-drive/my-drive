class AddIconLinkToUserFile < ActiveRecord::Migration[6.1]
  def change
    add_column :user_files, :icon_link, :string
  end
end
