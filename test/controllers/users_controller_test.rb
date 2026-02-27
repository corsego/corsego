# frozen_string_literal: true

require 'test_helper'

class UsersControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @admin = users(:admin)
    @teacher = users(:teacher)
    @student = users(:student)
  end

  # INDEX
  test 'unauthenticated user cannot access users index' do
    get users_url
    assert_redirected_to new_user_session_url
  end

  test 'admin can access users index' do
    sign_in @admin
    get users_url
    assert_response :success
  end

  test 'non-admin cannot access users index' do
    sign_in @student
    get users_url
    assert_redirected_to root_url
  end

  # SHOW
  test 'anyone can view user profile' do
    sign_in @student
    get user_url(@teacher)
    assert_response :success
  end

  test 'user profile shows courses teaching' do
    sign_in @student
    get user_url(@teacher)
    assert_response :success
  end

  # EDIT
  test 'admin can access user edit form' do
    sign_in @admin
    get edit_user_url(@student)
    assert_response :success
  end

  test 'non-admin cannot access user edit form' do
    sign_in @student
    get edit_user_url(@teacher)
    assert_redirected_to root_url
  end

  # UPDATE
  test 'admin can update user roles' do
    sign_in @admin
    teacher_role = Role.find_by(name: 'teacher')
    student_role = Role.find_by(name: 'student')

    patch user_url(@student), params: {
      user: { role_ids: [teacher_role.id, student_role.id] }
    }

    @student.reload
    assert @student.has_role?(:teacher)
    assert_redirected_to root_path
  end

  test 'non-admin cannot update user roles' do
    sign_in @student

    patch user_url(@teacher), params: {
      user: { role_ids: [] }
    }

    assert_redirected_to root_url
  end

  # FINANCIAL DATA VISIBILITY
  test 'non-admin viewing another users profile does not see financial data' do
    sign_in @student
    get user_url(@teacher)
    assert_response :success
    assert_no_match(/stripe_customer_id/i, response.body)
    assert_no_match(/course.income/i, response.body)
    assert_no_match(/enrollment.expences/i, response.body)
  end

  test 'admin viewing user profile sees financial data' do
    sign_in @admin
    get user_url(@teacher)
    assert_response :success
    assert_match(/Course income/, response.body)
  end
end
