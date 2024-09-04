class Parent < ApplicationRecord
  has_one :has_parents
  has_many :items, through: :has_parents
end
