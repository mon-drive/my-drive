class AddWebLinkToUserFile < ActiveRecord::Migration[6.1]
  def change
    add_column :user_files, :web_view_link, :string
  end
end
