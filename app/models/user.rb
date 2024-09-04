class User < ApplicationRecord
  self.inheritance_column = :type

  has_one :premium_user, dependent: :destroy
  has_one :admin_user, dependent: :destroy

  has_many :makes
  has_many :transactions, through: :makes
  has_many :possesses
  has_many :user_folders, through: :possesses
  has_many :share_folders
  has_many :shared_folders, through: :share_folders, source: :user_folder
  has_many :share_files
  has_many :shared_files, through: :share_files, source: :user_file

  def self.from_omniauth(auth)
    user = where(provider: auth.provider, user_id: auth.uid).first_or_create do |user|
      user.username = auth.info.name if user.username.blank?
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
