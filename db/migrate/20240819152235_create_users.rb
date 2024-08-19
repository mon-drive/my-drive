class CreateUsers < ActiveRecord::Migration[6.1]
  def change
    create_table :users do |t|
      t.string :username
      t.string :type # STI column
      t.string :email
      t.string :profile_picture
      t.date :expire_date # Solo per PremiumUser
      t.string :provider
      t.string :uid
      t.string :oauth_token
      t.string :refresh_token
      t.datetime :oauth_expires_at

      t.timestamps
    end
  end
end
