# frozen_string_literal: true

class UserLesson < ApplicationRecord
  belongs_to :user, counter_cache: true
  belongs_to :lesson, counter_cache: true

  validates :user, :lesson, presence: true

  validates :user_id, uniqueness: { scope: :lesson_id } # user cant see the same lesson twice for the first time
  validates :lesson_id, uniqueness: { scope: :user_id }

  after_create_commit :update_enrollment_completion
  after_destroy_commit :update_enrollment_completion

  private

  def update_enrollment_completion
    enrollment = Enrollment.find_by(user_id: user_id, course_id: lesson.course_id)
    enrollment&.update_completion_percentage!
  end
end
