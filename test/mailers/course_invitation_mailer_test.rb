# frozen_string_literal: true

require 'test_helper'

class CourseInvitationMailerTest < ActionMailer::TestCase
  setup do
    @course = courses(:course_with_invites)
    @teacher = users(:teacher)
  end

  test 'invite email is sent with correct recipient' do
    email = CourseInvitationMailer.invite(
      course: @course,
      email: 'invitee@example.com',
      invited_by: @teacher
    )

    assert_equal ['invitee@example.com'], email.to
  end

  test 'invite email has correct subject' do
    email = CourseInvitationMailer.invite(
      course: @course,
      email: 'invitee@example.com',
      invited_by: @teacher
    )

    assert_includes email.subject, @course.title
    assert_includes email.subject, 'invited'
  end

  test 'invite email contains course title' do
    email = CourseInvitationMailer.invite(
      course: @course,
      email: 'invitee@example.com',
      invited_by: @teacher
    )

    assert_includes email.body.encoded, @course.title
  end

  test 'invite email contains inviter username' do
    email = CourseInvitationMailer.invite(
      course: @course,
      email: 'invitee@example.com',
      invited_by: @teacher
    )

    assert_includes email.body.encoded, @teacher.username
  end

  test 'invite email contains invite token in URL' do
    email = CourseInvitationMailer.invite(
      course: @course,
      email: 'invitee@example.com',
      invited_by: @teacher
    )

    assert_includes email.body.encoded, @course.invite_token
  end

  test 'invite email is sent from correct address' do
    email = CourseInvitationMailer.invite(
      course: @course,
      email: 'invitee@example.com',
      invited_by: @teacher
    )

    assert_includes email.from, 'hello@corsego.com'
  end
end
