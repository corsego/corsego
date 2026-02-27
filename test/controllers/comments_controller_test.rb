# frozen_string_literal: true

require 'test_helper'

class CommentsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @admin = users(:admin)
    @teacher = users(:teacher)
    @student = users(:student)
    @another_teacher = users(:another_teacher)
    @published_course = courses(:published_course)
    @lesson = lessons(:lesson_one)
    @comment = comments(:student_comment)
  end

  # CREATE
  test 'enrolled user can create comment' do
    sign_in @student
    assert_difference 'Comment.count', 1 do
      post course_lesson_comments_url(@published_course, @lesson), params: {
        comment: { content: 'Nice lesson!' }
      }
    end
    assert_redirected_to course_lesson_path(@published_course, @lesson, anchor: 'current_lesson')
  end

  test 'non-enrolled user cannot create comment' do
    sign_in @another_teacher
    assert_no_difference 'Comment.count' do
      post course_lesson_comments_url(@published_course, @lesson), params: {
        comment: { content: 'Should not be allowed' }
      }
    end
    assert_redirected_to root_url
  end

  test 'unauthenticated user cannot create comment' do
    assert_no_difference 'Comment.count' do
      post course_lesson_comments_url(@published_course, @lesson), params: {
        comment: { content: 'Anonymous comment' }
      }
    end
  end

  # DESTROY
  test 'comment owner can destroy comment' do
    sign_in @student
    assert_difference 'Comment.count', -1 do
      delete course_lesson_comment_url(@published_course, @lesson, @comment)
    end
    assert_redirected_to course_lesson_path(@published_course, @lesson, anchor: 'current_lesson')
  end

  test 'course owner can destroy comment' do
    sign_in @teacher
    assert_difference 'Comment.count', -1 do
      delete course_lesson_comment_url(@published_course, @lesson, @comment)
    end
  end

  test 'non-owner cannot destroy comment' do
    sign_in @another_teacher
    assert_no_difference 'Comment.count' do
      delete course_lesson_comment_url(@published_course, @lesson, @comment)
    end
    assert_redirected_to root_url
  end
end
