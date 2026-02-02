# frozen_string_literal: true

require 'test_helper'

class CourseInvitationsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @teacher = users(:teacher)
    @student = users(:student)
    @another_teacher = users(:another_teacher)
    @published_course = courses(:published_course)
    @course_with_invites = courses(:course_with_invites)
  end

  # SHOW
  test 'unauthenticated user cannot access invitations page' do
    get course_invitations_url(@published_course)
    assert_redirected_to new_user_session_url
  end

  test 'non-owner cannot access invitations page' do
    sign_in @student
    get course_invitations_url(@published_course)
    assert_redirected_to root_url
  end

  test 'course owner can access invitations page' do
    sign_in @teacher
    get course_invitations_url(@published_course)
    assert_response :success
  end

  # TOGGLE
  test 'unauthenticated user cannot toggle invitations' do
    patch toggle_course_invitations_url(@published_course)
    assert_redirected_to new_user_session_url
  end

  test 'non-owner cannot toggle invitations' do
    sign_in @student
    patch toggle_course_invitations_url(@published_course)
    assert_redirected_to root_url
  end

  test 'course owner can enable invite sharing' do
    sign_in @teacher
    assert_not @published_course.invite_enabled?

    patch toggle_course_invitations_url(@published_course)

    @published_course.reload
    assert @published_course.invite_enabled?
    assert @published_course.invite_token.present?
    assert_redirected_to course_url(@published_course)
  end

  test 'course owner can disable invite sharing' do
    sign_in @teacher
    assert @course_with_invites.invite_enabled?

    patch toggle_course_invitations_url(@course_with_invites)

    @course_with_invites.reload
    assert_not @course_with_invites.invite_enabled?
    assert_redirected_to course_url(@course_with_invites)
  end

  # REGENERATE_TOKEN
  test 'unauthenticated user cannot regenerate token' do
    post regenerate_token_course_invitations_url(@course_with_invites)
    assert_redirected_to new_user_session_url
  end

  test 'non-owner cannot regenerate token' do
    sign_in @student
    post regenerate_token_course_invitations_url(@course_with_invites)
    assert_redirected_to root_url
  end

  test 'course owner can regenerate invite token' do
    sign_in @teacher
    old_token = @course_with_invites.invite_token

    post regenerate_token_course_invitations_url(@course_with_invites)

    @course_with_invites.reload
    assert_not_equal old_token, @course_with_invites.invite_token
    assert_redirected_to course_invitations_url(@course_with_invites)
  end

  # SEND_EMAILS
  test 'unauthenticated user cannot send invitation emails' do
    post send_emails_course_invitations_url(@course_with_invites), params: { emails: 'test@example.com' }
    assert_redirected_to new_user_session_url
  end

  test 'non-owner cannot send invitation emails' do
    sign_in @student
    post send_emails_course_invitations_url(@course_with_invites), params: { emails: 'test@example.com' }
    assert_redirected_to root_url
  end

  test 'course owner can send invitation emails' do
    sign_in @teacher

    assert_enqueued_emails 2 do
      post send_emails_course_invitations_url(@course_with_invites),
           params: { emails: "test1@example.com, test2@example.com" }
    end

    assert_redirected_to course_invitations_url(@course_with_invites)
    assert_match(/2 recipients/, flash[:notice])
  end

  test 'send_emails with empty emails shows error' do
    sign_in @teacher
    post send_emails_course_invitations_url(@course_with_invites), params: { emails: '' }

    assert_redirected_to course_invitations_url(@course_with_invites)
    assert_match(/at least one email/, flash[:alert])
  end

  test 'send_emails enables invite sharing if not already enabled' do
    sign_in @teacher
    @published_course.update!(invite_enabled: false, invite_token: nil)

    post send_emails_course_invitations_url(@published_course), params: { emails: 'test@example.com' }

    @published_course.reload
    assert @published_course.invite_enabled?
    assert @published_course.invite_token.present?
  end

  # ACCEPT
  test 'accept with invalid token redirects with error' do
    get accept_course_invitations_url(@course_with_invites, token: 'invalid_token')
    assert_redirected_to course_url(@course_with_invites)
    assert_match(/Invalid or expired/, flash[:alert])
  end

  test 'accept with valid token redirects unauthenticated user to sign up' do
    get accept_course_invitations_url(@course_with_invites, token: 'test_invite_token_abc123')

    assert_redirected_to new_user_registration_url
    assert session[:pending_course_invite].present?
  end

  test 'accept with valid token enrolls signed in user' do
    sign_in @student

    assert_difference 'Enrollment.count', 1 do
      get accept_course_invitations_url(@course_with_invites, token: 'test_invite_token_abc123')
    end

    enrollment = Enrollment.last
    assert_equal @student, enrollment.user
    assert_equal @course_with_invites, enrollment.course
    assert_equal 0, enrollment.price
    assert enrollment.invited?

    assert_redirected_to course_url(@course_with_invites)
    assert_match(/enrolled.*free/, flash[:notice])
  end

  test 'accept does not enroll user who is already enrolled' do
    sign_in @student
    # Create enrollment first
    @student.enrollments.create!(course: @course_with_invites, price: 100, invited: false)

    assert_no_difference 'Enrollment.count' do
      get accept_course_invitations_url(@course_with_invites, token: 'test_invite_token_abc123')
    end

    assert_redirected_to course_url(@course_with_invites)
    assert_match(/already enrolled/, flash[:notice])
  end

  test 'accept does not allow course owner to enroll in own course' do
    sign_in @teacher

    assert_no_difference 'Enrollment.count' do
      get accept_course_invitations_url(@course_with_invites, token: 'test_invite_token_abc123')
    end

    assert_redirected_to course_url(@course_with_invites)
    assert_match(/cannot enroll in your own course/, flash[:alert])
  end

  test 'accept with disabled invite link fails' do
    @course_with_invites.update!(invite_enabled: false)

    get accept_course_invitations_url(@course_with_invites, token: 'test_invite_token_abc123')
    assert_redirected_to course_url(@course_with_invites)
    assert_match(/Invalid or expired/, flash[:alert])
  end
end
