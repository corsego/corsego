class Comment < ApplicationRecord

  belongs_to :user
  belongs_to :lesson
  validates :content, presence: true

end