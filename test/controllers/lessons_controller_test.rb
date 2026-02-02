# frozen_string_literal: true

require 'test_helper'

class LessonsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @admin = users(:admin)
    @teacher = users(:teacher)
    @student = users(:student)
    @another_teacher = users(:another_teacher)
    @published_course = courses(:published_course)
    @unpublished_course = courses(:unpublished_course)
    @free_course = courses(:free_course)
    @lesson_one = lessons(:lesson_one)
    @lesson_two = lessons(:lesson_two)
    @chapter_one = chapters(:chapter_one)
  end

  # SHOW
  test 'unauthenticated user cannot view lesson' do
    get course_lesson_url(@published_course, @lesson_one)
    assert_redirected_to new_user_session_url
  end

  test 'enrolled student can view lesson' do
    sign_in @student
    get course_lesson_url(@published_course, @lesson_one)
    assert_response :success
  end

  test 'course owner can view lesson' do
    sign_in @teacher
    get course_lesson_url(@published_course, @lesson_one)
    assert_response :success
  end

  test 'admin can view any lesson' do
    sign_in @admin
    get course_lesson_url(@published_course, @lesson_one)
    assert_response :success
  end

  test 'non-enrolled user cannot view lesson' do
    sign_in @another_teacher
    get course_lesson_url(@published_course, @lesson_one)
    assert_redirected_to root_url
  end

  test 'viewing lesson tracks user progress' do
    sign_in @student

    assert_difference 'UserLesson.count', 1 do
      get course_lesson_url(@published_course, @lesson_one)
    end
  end

  # NEW
  test 'course owner can access new lesson form' do
    sign_in @teacher
    get new_course_lesson_url(@published_course)
    assert_response :success
  end

  test 'non-owner cannot access new lesson form' do
    sign_in @student
    get new_course_lesson_url(@published_course)
    assert_redirected_to root_url
  end

  # CREATE
  test 'course owner can create lesson' do
    sign_in @teacher

    assert_difference 'Lesson.count', 1 do
      post course_lessons_url(@published_course), params: {
        lesson: {
          title: 'New Lesson',
          content: 'New lesson content',
          chapter_id: @chapter_one.id
        }
      }
    end

    lesson = Lesson.last
    assert_redirected_to course_lesson_path(@published_course, lesson, anchor: 'current_lesson')
  end

  test 'create lesson with invalid data renders new' do
    sign_in @teacher

    assert_no_difference 'Lesson.count' do
      post course_lessons_url(@published_course), params: {
        lesson: { title: '', content: '', chapter_id: @chapter_one.id }
      }
    end

    assert_response :success
  end

  # EDIT
  test 'course owner can access edit lesson form' do
    sign_in @teacher
    get edit_course_lesson_url(@published_course, @lesson_one)
    assert_response :success
  end

  test 'non-owner cannot access edit lesson form' do
    sign_in @student
    get edit_course_lesson_url(@published_course, @lesson_one)
    assert_redirected_to root_url
  end

  # UPDATE
  test 'course owner can update lesson' do
    sign_in @teacher

    patch course_lesson_url(@published_course, @lesson_one), params: {
      lesson: { title: 'Updated Title', content: 'Updated content for lesson' }
    }

    @lesson_one.reload
    assert_equal 'Updated Title', @lesson_one.title
    assert_redirected_to course_lesson_path(@published_course, @lesson_one, anchor: 'current_lesson')
  end

  test 'non-owner cannot update lesson' do
    sign_in @student
    original_title = @lesson_one.title

    patch course_lesson_url(@published_course, @lesson_one), params: {
      lesson: { title: 'Hacked Title' }
    }

    @lesson_one.reload
    assert_equal original_title, @lesson_one.title
    assert_redirected_to root_url
  end

  # DESTROY
  test 'course owner can destroy lesson' do
    sign_in @teacher

    assert_difference 'Lesson.count', -1 do
      delete course_lesson_url(@published_course, @lesson_one)
    end

    assert_redirected_to course_path(@published_course)
  end

  test 'non-owner cannot destroy lesson' do
    sign_in @student

    assert_no_difference 'Lesson.count' do
      delete course_lesson_url(@published_course, @lesson_one)
    end

    assert_redirected_to root_url
  end
end
