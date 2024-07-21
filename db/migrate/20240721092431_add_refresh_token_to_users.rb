class AddRefreshTokenToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :refresh_token, :string
  end
end
