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
    @unpublished_course = courses(:unpublished_course)
    @lesson_one = lessons(:lesson_one)
    @lesson_advanced = lessons(:lesson_advanced)
  end

  # CREATE
  test 'unauthenticated user cannot create comment' do
    assert_no_difference 'Comment.count' do
      post course_lesson_comments_url(@published_course, @lesson_one),
           params: { comment: { content: 'Great lesson!' } }
    end

    assert_redirected_to new_user_session_url
  end

  test 'enrolled student can create comment on lesson' do
    sign_in @student

    assert_difference 'Comment.count', 1 do
      post course_lesson_comments_url(@published_course, @lesson_one),
           params: { comment: { content: 'Great lesson!' } }
    end

    assert_redirected_to course_lesson_path(@published_course, @lesson_one, anchor: 'current_lesson')
  end

  test 'course owner can create comment on their own lesson' do
    sign_in @teacher

    assert_difference 'Comment.count', 1 do
      post course_lesson_comments_url(@published_course, @lesson_one),
           params: { comment: { content: 'Thanks for joining!' } }
    end

    assert_redirected_to course_lesson_path(@published_course, @lesson_one, anchor: 'current_lesson')
  end

  test 'admin can create comment on any lesson' do
    sign_in @admin

    assert_difference 'Comment.count', 1 do
      post course_lesson_comments_url(@published_course, @lesson_one),
           params: { comment: { content: 'Admin comment' } }
    end

    assert_redirected_to course_lesson_path(@published_course, @lesson_one, anchor: 'current_lesson')
  end

  test 'non-enrolled user cannot create comment on lesson' do
    sign_in @another_teacher

    assert_no_difference 'Comment.count' do
      post course_lesson_comments_url(@published_course, @lesson_one),
           params: { comment: { content: 'Cannot comment!' } }
    end

    assert_redirected_to root_url
  end

  test 'user cannot create comment on unpublished course lesson' do
    sign_in @student

    assert_no_difference 'Comment.count' do
      post course_lesson_comments_url(@unpublished_course, @lesson_advanced),
           params: { comment: { content: 'Should not work!' } }
    end

    assert_redirected_to root_url
  end

  # DESTROY
  test 'comment owner can destroy their comment' do
    sign_in @student
    comment = Comment.create!(
      content: 'Test comment',
      user: @student,
      lesson: @lesson_one
    )

    assert_difference 'Comment.count', -1 do
      delete course_lesson_comment_url(@published_course, @lesson_one, comment)
    end

    assert_redirected_to course_lesson_path(@published_course, @lesson_one, anchor: 'current_lesson')
  end

  test 'course owner can destroy any comment on their course' do
    sign_in @teacher
    comment = Comment.create!(
      content: 'Student comment',
      user: @student,
      lesson: @lesson_one
    )

    assert_difference 'Comment.count', -1 do
      delete course_lesson_comment_url(@published_course, @lesson_one, comment)
    end

    assert_redirected_to course_lesson_path(@published_course, @lesson_one, anchor: 'current_lesson')
  end

  test 'admin can destroy any comment' do
    sign_in @admin
    comment = Comment.create!(
      content: 'Student comment',
      user: @student,
      lesson: @lesson_one
    )

    assert_difference 'Comment.count', -1 do
      delete course_lesson_comment_url(@published_course, @lesson_one, comment)
    end

    assert_redirected_to course_lesson_path(@published_course, @lesson_one, anchor: 'current_lesson')
  end

  test 'other users cannot destroy comments they do not own' do
    sign_in @another_teacher
    comment = Comment.create!(
      content: 'Student comment',
      user: @student,
      lesson: @lesson_one
    )

    assert_no_difference 'Comment.count' do
      delete course_lesson_comment_url(@published_course, @lesson_one, comment)
    end

    assert_redirected_to root_url
  end
end
