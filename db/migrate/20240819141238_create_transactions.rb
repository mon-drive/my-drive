class CreateTransactions < ActiveRecord::Migration[6.1]
  def change
    create_table :transactions do |t|
      t.datetime :data
      t.string :transaction_type
      
      t.timestamps
    end
  end
end
