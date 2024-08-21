class UserFile < ApplicationRecord
  self.table_name = 'files'

  has_many :converts
  has_many :premium_users, through: :converts
  
  has_many :contains
  has_many :folders, through: :contains

  has_many :has_parents, as: :item
  has_many :parents, through: :has_parents

  has_many :has_permissions, as: :item
  has_many :permissions, through: :has_permissions

  has_many :has_owners, as: :item
  has_many :owners, through: :has_owners

end
