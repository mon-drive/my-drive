class ShareFolder < ApplicationRecord
  belongs_to :user
  belongs_to :user_folder
end
