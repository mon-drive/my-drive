class MakeTransaction < ApplicationRecord
  belongs_to :user
  belongs_to :pay_transaction
end
