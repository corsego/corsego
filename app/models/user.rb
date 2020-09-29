class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :lockable, :timeoutable, and :omniauthable
  devise :database_authenticatable, :registerable,
    :recoverable, :rememberable, :validatable, :trackable, :confirmable,
    :omniauthable, omniauth_providers: [:google_oauth2, :github, :facebook]

  rolify

  has_many :courses, dependent: :nullify
  has_many :enrollments, dependent: :nullify
  has_many :user_lessons, dependent: :nullify
  has_many :comments, dependent: :nullify
  has_many :students, through: :courses, source: :enrollments
  # has_many :enrolled_courses, through: :enrollments, source: :course
  # def enrolled_in?(course)
  #  return enrolled_courses.include?(course)
  # end

  after_create do
    UserMailer.new_user(self).deliver_later
  end

  include PublicActivity::Model
  tracked only: [:create, :destroy], owner: :itself
  # tracked owner: Proc.new{ |controller, model| controller.current_user } #current_user is set after create, so it gives an error

  def self.from_omniauth(access_token)
    data = access_token.info
    user = User.where(email: data["email"]).first

    user ||= User.create(
      email: data["email"],
      password: Devise.friendly_token[0, 20]
    )

    user.name = access_token.info.name
    user.image = access_token.info.image
    user.provider = access_token.provider
    user.uid = access_token.uid
    user.token = access_token.credentials.token
    user.expires_at = access_token.credentials.expires_at
    user.expires = access_token.credentials.expires
    user.refresh_token = access_token.credentials.refresh_token
    user.confirmed_at = Time.now # autoconfirm user from omniauth

    user
  end

  def to_s
    email
  end

  def username
    email.split(/@/).first
  end

  extend FriendlyId
  friendly_id :email_or_id, use: :slugged
  def email_or_id
    if email.present?
      email
    else
      id
    end
  end

  after_create :assign_default_role

  def assign_default_role
    if User.count == 1
      add_role(:admin) if roles.blank?
      add_role(:teacher)
      add_role(:student)
    else
      add_role(:student) if roles.blank?
      add_role(:teacher) # if you want any user to be able to create own courses
    end
  end

  validate :must_have_a_role, on: :update

  def online?
    updated_at > 2.minutes.ago
  end

  def buy_course(course)
    enrollments.create(course: course, price: course.price)
  end

  def view_lesson(lesson)
    user_lesson = user_lessons.where(lesson: lesson)
    if user_lesson.any?
      user_lesson.first.increment!(:impressions)
    else
      user_lessons.create(lesson: lesson)
    end
  end

  def calculate_course_income
    update_column :course_income, courses.map(&:income).sum
    update_column :balance, (course_income - enrollment_expences)
  end

  def calculate_enrollment_expences
    update_column :enrollment_expences, enrollments.map(&:price).sum
    update_column :balance, (course_income - enrollment_expences)
  end

  private

  def must_have_a_role
    unless roles.any?
      errors.add(:roles, "must have at least one role")
    end
  end
end
