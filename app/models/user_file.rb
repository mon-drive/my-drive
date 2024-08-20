class UserFile < ApplicationRecord
  self.table_name = 'files'

  has_many :converts
  has_many :premium_users, through: :converts
  has_many :contains
  has_many :folders, through: :contains
end
