class Permission < ApplicationRecord

  has_many :has_permissions
  has_many :items, through: :has_permissions

  # Puoi aggiungere eventuali validazioni per garantire che i campi siano corretti.
  validates :permission_type, :role, :emailAddress, presence: true
end
