class Contains < ApplicationRecord
  belongs_to :user_folder
  belongs_to :user_file
  validates :user_file_id, :user_folder_id, presence: true
end
