# frozen_string_literal: true

require 'test_helper'

class EnrollmentMailerTest < ActionMailer::TestCase
  test 'student_enrollment sends email to enrolled student' do
    enrollment = enrollments(:student_enrollment)
    mail = EnrollmentMailer.student_enrollment(enrollment)

    assert_emails 1 do
      mail.deliver_now
    end

    assert_equal [enrollment.user.email], mail.to
    assert_match 'Welcome', mail.subject
    assert_match enrollment.course.title, mail.subject
  end

  test 'student_enrollment email body contains expected content' do
    enrollment = enrollments(:student_enrollment)
    mail = EnrollmentMailer.student_enrollment(enrollment)

    assert_match enrollment.course.title, mail.body.encoded
    assert_match 'enrolled', mail.body.encoded
  end

  test 'student_enrollment email is properly formatted' do
    enrollment = enrollments(:student_enrollment)
    mail = EnrollmentMailer.student_enrollment(enrollment)

    assert_match 'Hello', mail.body.encoded
    assert_match 'Best regards', mail.body.encoded
    assert_match 'Corsego', mail.body.encoded
  end

  test 'teacher_enrollment sends email to course teacher' do
    enrollment = enrollments(:student_enrollment)
    mail = EnrollmentMailer.teacher_enrollment(enrollment)

    assert_emails 1 do
      mail.deliver_now
    end

    assert_equal [enrollment.course.user.email], mail.to
    assert_match 'enrollment', mail.subject.downcase
    assert_match enrollment.course.title, mail.subject
  end

  test 'teacher_enrollment email body contains student info' do
    enrollment = enrollments(:student_enrollment)
    mail = EnrollmentMailer.teacher_enrollment(enrollment)

    assert_match enrollment.user.username, mail.body.encoded
    assert_match enrollment.course.title, mail.body.encoded
  end

  test 'teacher_enrollment email is properly formatted' do
    enrollment = enrollments(:student_enrollment)
    mail = EnrollmentMailer.teacher_enrollment(enrollment)

    assert_match 'Hello', mail.body.encoded
    assert_match 'Best regards', mail.body.encoded
    assert_match 'Corsego', mail.body.encoded
  end
end
