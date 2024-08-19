class ShareFolder < ApplicationRecord
  belongs_to :user
  belongs_to :folder
end
