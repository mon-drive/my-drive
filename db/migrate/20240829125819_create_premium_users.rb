class CreatePremiumUsers < ActiveRecord::Migration[6.1]
  def change
    create_table :premium_users do |t|
      t.references :user, null: false, foreign_key: true # Relazione con la tabella Users
      t.date :expire_date
      # Qualsiasi altro attributo specifico per PremiumUser

      t.timestamps
    end
  end
end
