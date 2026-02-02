# frozen_string_literal: true

require 'test_helper'

class ChartsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @admin = users(:admin)
    @teacher = users(:teacher)
    @student = users(:student)
  end

  # USERS_PER_DAY
  test 'unauthenticated user cannot access users_per_day' do
    get charts_users_per_day_url
    assert_redirected_to new_user_session_url
  end

  test 'admin can access users_per_day' do
    sign_in @admin
    get charts_users_per_day_url
    assert_response :success
  end

  test 'non-admin cannot access users_per_day' do
    sign_in @student
    get charts_users_per_day_url
    assert_redirected_to root_url
  end

  test 'teacher cannot access users_per_day' do
    sign_in @teacher
    get charts_users_per_day_url
    assert_redirected_to root_url
  end

  # ENROLLMENTS_PER_DAY
  test 'unauthenticated user cannot access enrollments_per_day' do
    get charts_enrollments_per_day_url
    assert_redirected_to new_user_session_url
  end

  test 'admin can access enrollments_per_day' do
    sign_in @admin
    get charts_enrollments_per_day_url
    assert_response :success
  end

  test 'non-admin cannot access enrollments_per_day' do
    sign_in @student
    get charts_enrollments_per_day_url
    assert_redirected_to root_url
  end

  # COURSE_POPULARITY
  test 'unauthenticated user cannot access course_popularity' do
    get charts_course_popularity_url
    assert_redirected_to new_user_session_url
  end

  test 'admin can access course_popularity' do
    sign_in @admin
    get charts_course_popularity_url
    assert_response :success
  end

  test 'non-admin cannot access course_popularity' do
    sign_in @student
    get charts_course_popularity_url
    assert_redirected_to root_url
  end

  # MONEY_MAKERS
  test 'unauthenticated user cannot access money_makers' do
    get charts_money_makers_url
    assert_redirected_to new_user_session_url
  end

  test 'admin can access money_makers' do
    sign_in @admin
    get charts_money_makers_url
    assert_response :success
  end

  test 'non-admin cannot access money_makers' do
    sign_in @student
    get charts_money_makers_url
    assert_redirected_to root_url
  end
end
