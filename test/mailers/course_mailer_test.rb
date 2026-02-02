# frozen_string_literal: true

require 'test_helper'

class CourseMailerTest < ActionMailer::TestCase
  test 'approved sends email to course owner for approved course' do
    course = courses(:published_course)
    mail = CourseMailer.approved(course)

    assert_emails 1 do
      mail.deliver_now
    end

    assert_equal [course.user.email], mail.to
    assert_match 'approved', mail.subject
    assert_match course.title, mail.subject
  end

  test 'approved email shows approval message for approved course' do
    course = courses(:published_course)
    assert course.approved?, 'Test fixture should be approved'

    mail = CourseMailer.approved(course)

    assert_match 'approved', mail.body.encoded
    assert_match course.title, mail.body.encoded
    assert_no_match 'not approved', mail.body.encoded
  end

  test 'approved email shows rejection message for unapproved course' do
    course = courses(:unpublished_course)
    assert_not course.approved?, 'Test fixture should not be approved'

    mail = CourseMailer.approved(course)

    assert_match 'not approved', mail.body.encoded
    assert_match course.title, mail.body.encoded
    assert_match 'quality guidelines', mail.body.encoded
  end

  test 'approved email is properly formatted' do
    course = courses(:published_course)
    mail = CourseMailer.approved(course)

    assert_match 'Hello', mail.body.encoded
    assert_match 'Best regards', mail.body.encoded
    assert_match 'Corsego', mail.body.encoded
  end
end
