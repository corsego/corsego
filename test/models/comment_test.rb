# frozen_string_literal: true

require 'test_helper'

class CommentTest < ActiveSupport::TestCase
  test 'comment with all required fields is valid' do
    comment = Comment.new(
      user: users(:student),
      lesson: lessons(:lesson_one),
      content: 'Great lesson!'
    )
    assert comment.valid?, comment.errors.full_messages.join(', ')
  end

  test 'comment requires content' do
    comment = Comment.new(
      user: users(:student),
      lesson: lessons(:lesson_one)
    )
    assert_not comment.valid?
    assert_includes comment.errors[:content], "can't be blank"
  end

  test 'belongs to user' do
    comment = comments(:student_comment)
    assert_equal users(:student), comment.user
  end

  test 'belongs to lesson' do
    comment = comments(:student_comment)
    assert_equal lessons(:lesson_one), comment.lesson
  end

  test 'creating comment increments user comments_count' do
    user = users(:admin)
    lesson = lessons(:lesson_two)
    initial_count = user.comments_count

    Comment.create!(user: user, lesson: lesson, content: 'New comment')
    user.reload

    assert_equal initial_count + 1, user.comments_count
  end

  test 'creating comment increments lesson comments_count' do
    lesson = lessons(:lesson_two)
    initial_count = lesson.comments_count

    Comment.create!(user: users(:admin), lesson: lesson, content: 'New comment')
    lesson.reload

    assert_equal initial_count + 1, lesson.comments_count
  end
end
