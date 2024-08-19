class User < ApplicationRecord
  self.inheritance_column = :type

  has_many :makes
  has_many :transactions, through: :makes
  has_many :possesses
  has_many :folders, through: :possesses
  has_many :share_folders
  has_many :shared_folders, through: :share_folders, source: :folder
  has_many :share_files
  has_many :shared_files, through: :share_files, source: :file

  def self.from_omniauth(auth)
    user = where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
      user.username = auth.info.name
      user.email = auth.info.email
    end
    user.update(
      oauth_token: auth.credentials.token,
      refresh_token: auth.credentials.refresh_token,
      oauth_expires_at: Time.at(auth.credentials.expires_at)
    )
    user
  end
end
