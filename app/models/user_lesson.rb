# frozen_string_literal: true

class UserLesson < ApplicationRecord
  belongs_to :user, counter_cache: true
  belongs_to :lesson, counter_cache: true

  validates :user, :lesson, presence: true

  validates :user_id, uniqueness: { scope: :lesson_id } # user cant see the same lesson twice for the first time
  validates :lesson_id, uniqueness: { scope: :user_id }
end
