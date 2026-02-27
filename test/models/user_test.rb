# frozen_string_literal: true

require 'test_helper'
require 'ostruct'

class UserTest < ActiveSupport::TestCase
  test 'user fixture is valid' do
    user = users(:student)
    assert user.valid?
  end

  test 'admin has admin role' do
    admin = users(:admin)
    assert admin.has_role?(:admin)
  end

  test 'teacher has teacher role' do
    teacher = users(:teacher)
    assert teacher.has_role?(:teacher)
  end

  test 'student has student role' do
    student = users(:student)
    assert student.has_role?(:student)
  end

  test 'user requires email' do
    user = User.new(password: 'password123')
    assert_not user.valid?
    assert_includes user.errors[:email], "can't be blank"
  end

  test 'user requires unique email' do
    existing = users(:student)
    user = User.new(email: existing.email, password: 'password123')
    assert_not user.valid?
    assert_includes user.errors[:email], 'has already been taken'
  end

  test 'username is derived from email' do
    user = users(:student)
    assert_equal 'student', user.username
  end

  test 'to_s returns email' do
    user = users(:student)
    assert_equal user.email, user.to_s
  end

  test 'user can buy a course' do
    student = users(:student)
    course = courses(:free_course)

    enrollment = student.buy_course(course)

    assert enrollment.persisted?
    assert_equal course.price, enrollment.price
    assert student.bought?(course)
  end

  test 'user cannot buy own course' do
    teacher = users(:teacher)
    course = courses(:published_course)

    enrollment = teacher.buy_course(course)

    assert_not enrollment.persisted?
    assert_includes enrollment.errors[:base], 'You can not subscribe to your own course'
  end

  test 'bought? returns true for enrolled course' do
    student = users(:student)
    course = courses(:published_course)

    assert student.bought?(course)
  end

  test 'bought? returns false for not enrolled course' do
    student = users(:student)
    course = courses(:unpublished_course)

    assert_not student.bought?(course)
  end

  test 'view_lesson creates user_lesson record' do
    student = users(:student)
    lesson = lessons(:lesson_one)

    assert_difference 'UserLesson.count', 1 do
      student.view_lesson(lesson)
    end
  end

  test 'view_lesson increments impressions on subsequent views' do
    student = users(:student)
    lesson = lessons(:lesson_one)

    student.view_lesson(lesson)
    user_lesson = UserLesson.find_by(user: student, lesson: lesson)
    initial_impressions = user_lesson.impressions

    student.view_lesson(lesson)
    user_lesson.reload

    assert_equal initial_impressions + 1, user_lesson.impressions
  end

  test 'viewed? returns true after viewing lesson' do
    student = users(:student)
    lesson = lessons(:lesson_one)

    student.view_lesson(lesson)

    assert student.viewed?(lesson)
  end

  test 'online? returns true if updated recently' do
    user = users(:student)
    user.update_column(:updated_at, 1.minute.ago)

    assert user.online?
  end

  test 'online? returns false if not updated recently' do
    user = users(:student)
    user.update_column(:updated_at, 5.minutes.ago)

    assert_not user.online?
  end

  test 'has many courses association' do
    teacher = users(:teacher)
    assert_respond_to teacher, :courses
    assert_includes teacher.courses, courses(:published_course)
  end

  test 'has many enrollments association' do
    student = users(:student)
    assert_respond_to student, :enrollments
    assert_includes student.enrollments, enrollments(:student_enrollment)
  end

  test 'has many enrolled_courses through enrollments' do
    student = users(:student)
    assert_respond_to student, :enrolled_courses
    assert_includes student.enrolled_courses, courses(:published_course)
  end

  # --- OmniAuth from_omniauth tests ---

  test 'from_omniauth returns existing user matched by provider and uid' do
    existing = users(:student)
    existing.update_columns(provider: 'google_oauth2', uid: '12345')

    access_token = mock_omniauth_token(
      provider: 'google_oauth2',
      uid: '12345',
      email: existing.email,
      name: 'Student User'
    )

    user = User.from_omniauth(access_token)
    assert_equal existing.id, user.id
  end

  test 'from_omniauth links legacy email-only user on first OAuth login' do
    existing = users(:student)
    # existing user registered via email — provider/uid are nil
    existing.update_columns(provider: nil, uid: nil)

    access_token = mock_omniauth_token(
      provider: 'google_oauth2',
      uid: 'first_oauth_uid',
      email: existing.email,
      name: 'Student User'
    )

    user = User.from_omniauth(access_token)
    # Should link to the existing account (legacy user, no provider set)
    assert_equal existing.id, user.id
  end

  test 'from_omniauth does not allow account takeover when user already has a different provider' do
    existing = users(:student)
    # existing user already linked to GitHub
    existing.update_columns(provider: 'github', uid: 'gh_existing_123')

    access_token = mock_omniauth_token(
      provider: 'google_oauth2',
      uid: 'attacker_uid_999',
      email: existing.email,
      name: 'Attacker'
    )

    user = User.from_omniauth(access_token)
    # Should NOT return the existing user — they already have a different provider
    assert_not_equal existing.id, user.id
    assert_equal 'google_oauth2', user.provider
    assert_equal 'attacker_uid_999', user.uid
  end

  test 'from_omniauth returns existing user when same provider+uid with different email' do
    existing = users(:student)
    existing.update_columns(provider: 'github', uid: 'gh_777')

    access_token = mock_omniauth_token(
      provider: 'github',
      uid: 'gh_777',
      email: 'newemail@example.com',
      name: 'Student New Email'
    )

    user = User.from_omniauth(access_token)
    assert_equal existing.id, user.id
  end

  test 'from_omniauth creates new user for completely new oauth user' do
    access_token = mock_omniauth_token(
      provider: 'google_oauth2',
      uid: 'brand_new_uid',
      email: 'brand_new@example.com',
      name: 'Brand New'
    )

    assert_difference 'User.count', 1 do
      user = User.from_omniauth(access_token)
      assert user.persisted?
      assert_equal 'brand_new@example.com', user.email
      assert_equal 'google_oauth2', user.provider
      assert_equal 'brand_new_uid', user.uid
      assert user.confirmed_at.present?
    end
  end

  private

  def mock_omniauth_token(provider:, uid:, email:, name:, image: nil, token: 'fake_token')
    OpenStruct.new(
      provider: provider,
      uid: uid,
      info: OpenStruct.new(email: email, name: name, image: image),
      credentials: OpenStruct.new(token: token, expires_at: nil, expires: false, refresh_token: nil)
    )
  end
end
