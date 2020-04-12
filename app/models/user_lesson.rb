class UserLesson < ApplicationRecord

  belongs_to :user
  belongs_to :lesson
  
  validates :user, :lesson, presence: true
  
  validates_uniqueness_of :user_id, scope: :lesson_id  #user cant see the same lesson twice for the first time
  validates_uniqueness_of :lesson_id, scope: :user_id

end