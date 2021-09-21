# frozen_string_literal: true

class Enrollment < ApplicationRecord
  belongs_to :course, counter_cache: true
  # Course.find_each { |course| Course.reset_counters(course.id, :enrollments) }
  belongs_to :user, counter_cache: true
  # User.find_each { |user| User.reset_counters(user.id, :enrollments) }

  validates :user, :course, presence: true

  validates :rating, presence: { if: :review? }
  validates :review, presence: { if: :rating? }

  validates :user_id, uniqueness: { scope: :course_id } # user cant be subscribed to the same course twice
  validates :course_id, uniqueness: { scope: :user_id } # user cant be subscribed to the same course twice

  validate :cant_subscribe_to_own_course # user can't create a subscription if course.user == current_user.id

  scope :pending_review, -> { where(rating: [0, nil, ''], review: [0, nil, '']) }
  scope :reviewed, -> { where.not(review: [0, nil, '']) }
  scope :latest_good_reviews, -> { order(rating: :desc, created_at: :desc).limit(3) }

  include PublicActivity::Model
  tracked owner: proc { |controller, _model| controller.current_user }

  extend FriendlyId
  friendly_id :to_s, use: :slugged

  def to_s
    "#{user} #{course}"
  end

  after_save do
    course.update_rating unless rating.nil? || rating.zero?
  end

  after_destroy do
    course.update_rating
  end

  after_create :calculate_balance
  after_destroy :calculate_balance
  def calculate_balance
    course.calculate_income
    user.calculate_enrollment_expences
  end

  protected

  def cant_subscribe_to_own_course
    errors.add(:base, 'You can not subscribe to your own course') if new_record? && user_id.present? && (user_id == course.user_id)
  end
end
