# frozen_string_literal: true

require 'test_helper'

class CommentMailerTest < ActionMailer::TestCase
  test 'new_comment sends email to course owner' do
    comment = comments(:student_comment)
    mail = CommentMailer.new_comment(comment)

    assert_emails 1 do
      mail.deliver_now
    end

    assert_equal [comment.lesson.course.user.email], mail.to
    assert_equal "New comment on your course: #{comment.lesson.course.title}", mail.subject
  end

  test 'new_comment email body contains expected content' do
    comment = comments(:student_comment)
    mail = CommentMailer.new_comment(comment)

    assert_match comment.lesson.course.title, mail.body.encoded
    assert_match comment.lesson.title, mail.body.encoded
    assert_match comment.user.username, mail.body.encoded
    assert_match comment.content.to_plain_text, mail.body.encoded
  end

  test 'new_comment email is properly formatted' do
    comment = comments(:student_comment)
    mail = CommentMailer.new_comment(comment)

    assert_match 'Hello', mail.body.encoded
    assert_match 'Best regards', mail.body.encoded
    assert_match 'Corsego', mail.body.encoded
  end
end
