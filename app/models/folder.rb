class Folder < ApplicationRecord
  has_many :contains
  has_many :files, through: :contains
  has_many :possesses
  has_many :users, through: :possesses
end
