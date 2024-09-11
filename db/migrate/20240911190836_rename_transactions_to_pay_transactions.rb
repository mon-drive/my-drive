class RenameTransactionsToPayTransactions < ActiveRecord::Migration[6.1]
  def change
    rename_table :transactions, :pay_transactions
  end
end
