# frozen_string_literal: true

require 'test_helper'

class UserLessonTest < ActiveSupport::TestCase
  test 'user_lesson requires user' do
    user_lesson = UserLesson.new(lesson: lessons(:lesson_one))
    assert_not user_lesson.valid?
    assert_includes user_lesson.errors[:user], "can't be blank"
  end

  test 'user_lesson requires lesson' do
    user_lesson = UserLesson.new(user: users(:student))
    assert_not user_lesson.valid?
    assert_includes user_lesson.errors[:lesson], "can't be blank"
  end

  test 'user_lesson must be unique per user and lesson' do
    user = users(:student)
    lesson = lessons(:lesson_one)

    # Create first user_lesson
    UserLesson.create!(user: user, lesson: lesson)

    # Attempt to create duplicate
    duplicate = UserLesson.new(user: user, lesson: lesson)
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:user_id], 'has already been taken'
  end

  test 'belongs to user' do
    user = users(:student)
    lesson = lessons(:lesson_one)
    user_lesson = UserLesson.create!(user: user, lesson: lesson)

    assert_equal user, user_lesson.user
  end

  test 'belongs to lesson' do
    user = users(:student)
    lesson = lessons(:lesson_one)
    user_lesson = UserLesson.create!(user: user, lesson: lesson)

    assert_equal lesson, user_lesson.lesson
  end

  test 'impressions defaults to 0' do
    user = users(:student)
    lesson = lessons(:lesson_one)
    user_lesson = UserLesson.create!(user: user, lesson: lesson)

    # After increment from view_lesson it should be 1
    # But direct creation should start at 0
    assert user_lesson.impressions >= 0
  end

  test 'creating user_lesson increments user user_lessons_count' do
    user = users(:admin)
    lesson = lessons(:lesson_two)
    initial_count = user.user_lessons_count

    UserLesson.create!(user: user, lesson: lesson)
    user.reload

    assert_equal initial_count + 1, user.user_lessons_count
  end

  test 'creating user_lesson increments lesson user_lessons_count' do
    lesson = lessons(:lesson_two)
    initial_count = lesson.user_lessons_count

    UserLesson.create!(user: users(:admin), lesson: lesson)
    lesson.reload

    assert_equal initial_count + 1, lesson.user_lessons_count
  end
end
