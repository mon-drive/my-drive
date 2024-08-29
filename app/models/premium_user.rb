class PremiumUser < User
  has_many :converts
  has_many :files, through: :converts
  belongs_to :user
end
