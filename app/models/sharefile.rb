class ShareFile < ApplicationRecord
  belongs_to :user
  belongs_to :file
end
