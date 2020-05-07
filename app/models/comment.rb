class Comment < ApplicationRecord

  include PublicActivity::Model
  tracked owner: Proc.new{ |controller, model| controller.current_user }

  belongs_to :user, counter_cache: true
  belongs_to :lesson, counter_cache: true
  #User.find_each { |user| User.reset_counters(user.id, :comments) }  
  #Lesson.find_each { |lesson| Lesson.reset_counters(lesson.id, :comments) }

  validates :content, presence: true
  
  has_rich_text :content
  
  def to_s
    content
  end

end