class RenameMakesToMakeTransactions < ActiveRecord::Migration[6.1]
  def change
    rename_table :makes, :make_transactions
  end
end
