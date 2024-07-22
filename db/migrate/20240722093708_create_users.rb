class CreateUsers < ActiveRecord::Migration[6.1]
  def change
    create_table :users do |t|
      t.string :name
      t.string :email
      t.string :uid
      t.string :provider
      t.string :oauth_token
      t.string :refresh_token
      t.datetime :oauth_expires_at

      t.timestamps
    end
  end
end
