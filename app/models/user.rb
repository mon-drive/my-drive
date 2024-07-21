class User < ApplicationRecord
    def self.from_omniauth(auth)
      user = where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
        user.name = auth.info.name
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
  