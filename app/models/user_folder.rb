class UserFolder < ApplicationRecord
  has_many :contains
  has_many :user_files, through: :contains

  has_many :possesses
  has_many :users, through: :possesses

  has_many :has_parents, as: :item
  has_many :parents, through: :has_parents

  has_many :has_permissions, as: :item
  has_many :permissions, through: :has_permissions

  has_many :has_owners, as: :item
  has_many :owners, through: :has_owners
end
