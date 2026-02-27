# frozen_string_literal: true

require 'test_helper'

class Courses::AccessGrantsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @admin = users(:admin)
    @teacher = users(:teacher)
    @student = users(:student)
    @another_teacher = users(:another_teacher)
    @published_course = courses(:published_course)
    @free_course = courses(:free_course)
  end

  # NEW

  test 'unauthenticated user cannot access grant access form' do
    get new_course_access_grant_url(@published_course)
    assert_redirected_to new_user_session_url
  end

  test 'course owner can access grant access form' do
    sign_in @teacher
    get new_course_access_grant_url(@published_course)
    assert_response :success
  end

  test 'admin can access grant access form' do
    sign_in @admin
    get new_course_access_grant_url(@published_course)
    assert_response :success
  end

  test 'non-owner non-admin cannot access grant access form' do
    sign_in @student
    get new_course_access_grant_url(@published_course)
    assert_redirected_to root_url
  end

  # CREATE - existing user

  test 'course owner can grant access to existing user' do
    sign_in @another_teacher

    assert_difference 'Enrollment.count', 1 do
      post course_access_grants_url(@free_course), params: {
        access_grant: { email: @student.email }
      }
    end

    assert_redirected_to course_path(@free_course)
    assert_match(/Access granted/, flash[:notice])
  end

  test 'admin can grant access to existing user' do
    sign_in @admin

    assert_difference 'Enrollment.count', 1 do
      post course_access_grants_url(@free_course), params: {
        access_grant: { email: @student.email }
      }
    end

    assert_redirected_to course_path(@free_course)
    assert_match(/Access granted/, flash[:notice])
  end

  # CREATE - new user (invite)

  test 'course owner can grant access to new email and invite user' do
    sign_in @another_teacher
    new_email = 'brand_new_student@example.com'

    assert_difference ['User.count', 'Enrollment.count'], 1 do
      post course_access_grants_url(@free_course), params: {
        access_grant: { email: new_email }
      }
    end

    assert_redirected_to course_path(@free_course)
    assert_match(/Access granted/, flash[:notice])

    invited_user = User.find_by(email: new_email)
    assert invited_user.present?
    assert invited_user.invitation_token.present?
    assert invited_user.enrolled_courses.include?(@free_course)
  end

  # CREATE - already enrolled

  test 'granting access to already enrolled user shows alert' do
    sign_in @teacher

    assert_no_difference 'Enrollment.count' do
      post course_access_grants_url(@published_course), params: {
        access_grant: { email: @student.email }
      }
    end

    assert_redirected_to new_course_access_grant_url(@published_course)
    assert_match(/already enrolled/, flash[:alert])
  end

  # CREATE - authorization

  test 'non-owner non-admin cannot create access grant' do
    sign_in @student

    assert_no_difference 'Enrollment.count' do
      post course_access_grants_url(@free_course), params: {
        access_grant: { email: 'someone@example.com' }
      }
    end

    assert_redirected_to root_url
  end

  # CREATE - blank email

  test 'blank email shows alert' do
    sign_in @another_teacher

    assert_no_difference ['User.count', 'Enrollment.count'] do
      post course_access_grants_url(@free_course), params: {
        access_grant: { email: '' }
      }
    end

    assert_redirected_to new_course_access_grant_url(@free_course)
    assert_match(/blank/, flash[:alert])
  end
end
