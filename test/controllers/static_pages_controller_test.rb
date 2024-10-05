require 'test_helper'

class StaticPagesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @admin = users(:admin)
    @admin.add_role :admin
    @user = users(:regular_user)
    @user.add_role :student
  end

  test "should get landing_page" do
    get root_url
    assert_response :success
  end

  test "admin should get activity" do
    sign_in @admin
    get activity_url
    assert_response :success
  end

  test "non-admin should not get activity" do
    sign_in @user
    get activity_url
    assert_redirected_to root_url
    assert_equal 'You are not authorized to access this page', flash[:alert]
  end

  test "admin should get analytics" do
    sign_in @admin
    get analytics_url
    assert_response :success
  end

  test "non-admin should not get analytics" do
    sign_in @user
    get analytics_url
    assert_redirected_to root_url
    assert_equal 'You are not authorized to access this page', flash[:alert]
  end

  test "should get privacy" do
    get privacy_url
    assert_response :success
  end

  test "should get terms" do
    get terms_url
    assert_response :success
  end

  test "should get about" do
    get about_url
    assert_response :success
  end
end
