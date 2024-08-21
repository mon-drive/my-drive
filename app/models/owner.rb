class Owner < ApplicationRecord
  has_many :has_owners
  has_many :items, through: :has_owners

  # Puoi aggiungere validazioni per garantire che i campi siano corretti.
  validates :displayName, :emailAddress, presence: true
end
