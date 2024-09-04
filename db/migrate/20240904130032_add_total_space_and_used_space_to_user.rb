class AddTotalSpaceAndUsedSpaceToUser < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :total_space, :integer
    add_column :users, :used_space, :integer
  end
end
