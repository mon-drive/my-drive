class RenameTransactionsId < ActiveRecord::Migration[6.1]
  def change
    rename_column :make_transactions, :transaction_id, :pay_transaction_id
  end
end
