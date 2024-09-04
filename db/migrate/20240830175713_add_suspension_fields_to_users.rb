class AddSuspensionFieldsToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :end_suspend, :datetime
    add_column :users, :suspended, :boolean
  end
end
