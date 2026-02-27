# frozen_string_literal: true

class User < ApplicationRecord
  devise :invitable, :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :trackable, :confirmable, :lockable,
         :omniauthable, omniauth_providers: %i[google_oauth2 github facebook]

  rolify

  has_many :courses, dependent: :nullify
  has_many :enrollments, dependent: :nullify
  has_many :user_lessons, dependent: :nullify
  has_many :comments, dependent: :nullify
  has_many :students, through: :courses, source: :enrollments
  has_many :lessons, through: :user_lessons # lessons viewed by the user

  has_many :enrolled_courses, through: :enrollments, source: :course

  after_create :assign_default_roles

  # External side effects: only fire after the DB transaction commits
  # so a rollback doesn't leave orphaned Stripe customers or spurious emails
  after_create_commit :send_welcome_notifications
  after_create_commit :create_stripe_customer

  include PublicActivity::Model
  tracked only: %i[create destroy], owner: :itself

  def self.from_omniauth(access_token)
    data = access_token.info

    # Look up by provider+uid first (secure primary path)
    user = User.find_by(provider: access_token.provider, uid: access_token.uid)

    # Fallback: match existing user by email ONLY if they have no provider set yet
    # (legacy user who registered via email and is now linking OAuth for the first time).
    # If the existing user already has a different provider+uid, do NOT match — that
    # would allow an attacker to claim someone else's account via a different OAuth provider.
    user ||= User.find_by(email: data['email'], provider: [nil, ''])

    user ||= User.create(
      email: data['email'],
      password: Devise.friendly_token[0, 20],
      provider: access_token.provider,
      uid: access_token.uid
    )

    user.name = access_token.info.name
    user.image = access_token.info.image
    user.provider = access_token.provider
    user.uid = access_token.uid
    user.token = access_token.credentials.token
    user.expires_at = access_token.credentials.expires_at
    user.expires = access_token.credentials.expires
    user.refresh_token = access_token.credentials.refresh_token
    user.confirmed_at = Time.zone.now # autoconfirm user from omniauth

    user
  end

  def to_s
    email
  end

  def username
    email.split(/@/).first
  end

  extend FriendlyId
  friendly_id :username_or_id, use: :slugged
  def username_or_id
    if email.present?
      username
    else
      id
    end
  end

  validate :must_have_a_role, on: :update

  def online?
    updated_at > 2.minutes.ago
  end

  def buy_course(course)
    enrollments.create(course: course, price: course.price)
  end

  # Idempotent enrollment creation - returns [enrollment, newly_created_flag]
  # Used by checkout success verification and webhook fallback
  def enroll_in_course(course, price:)
    enrollment = enrollments.find_by(course: course)
    return [enrollment, false] if enrollment.present?

    enrollment = enrollments.create(course: course, price: price)
    [enrollment, enrollment.persisted?]
  end

  def view_lesson(lesson)
    view = user_lessons.find_or_create_by(lesson: lesson)
    view.increment!(:impressions)
  end

  def bought?(course)
    enrollments.exists?(course: course)
  end

  def viewed?(lesson)
    user_lessons.exists?(lesson: lesson)
  end

  def calculate_course_income
    update_column :course_income, courses.sum(:income)
    update_column :balance, (course_income - enrollment_expences)
  end

  def calculate_enrollment_expences
    update_column :enrollment_expences, enrollments.sum(:price)
    update_column :balance, (course_income - enrollment_expences)
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[name email created_at updated_at courses_count enrollments_count]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[courses enrollments roles]
  end

  private

  def assign_default_roles
    if User.count == 1
      add_role(:admin) if roles.blank?
      add_role(:teacher)
      add_role(:student)
    else
      add_role(:student) if roles.blank?
      add_role(:teacher)
    end
  end

  def send_welcome_notifications
    UserMailer.new_user(self).deliver_later
  end

  def create_stripe_customer
    Stripe::Customer.create(email: email)
  end

  def must_have_a_role
    errors.add(:roles, 'must have at least one role') unless roles.any?
  end
end
