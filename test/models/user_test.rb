# frozen_string_literal: true

require 'test_helper'

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
end
