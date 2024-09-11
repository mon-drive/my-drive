class PayTransaction < ApplicationRecord
  has_many :make_transactions
  has_many :users, through: :make_transactions
end
