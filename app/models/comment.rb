class Comment < ApplicationRecord

  belongs_to :user, counter_cache: true
  belongs_to :lesson, counter_cache: true
  #User.find_each { |user| User.reset_counters(user.id, :comments) }  
  #Lesson.find_each { |lesson| Lesson.reset_counters(lesson.id, :comments) }

  validates :content, presence: true

end