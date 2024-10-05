require "application_system_test_case"

class StaticPagesTest < ApplicationSystemTestCase
  setup do
    @admin = users(:admin)
    @admin.add_role :admin
    @user = users(:regular_user)
    @user.add_role :student
  end

  test "visiting the landing page" do
    visit root_url
    assert_selector "h1", text: "Welcome to Our Course Platform"
    assert_selector ".course", minimum: 1
    assert_selector ".popular-tag", minimum: 1
  end

  test "admin can visit activity page" do
    sign_in @admin
    visit activity_url
    assert_selector "h1", text: "Activity"
    assert_selector ".activity-item", minimum: 1
  end

  test "regular user cannot visit activity page" do
    sign_in @user
    visit activity_url
    assert_text "You are not authorized to access this page"
    assert_current_path root_path
  end

  test "admin can visit analytics page" do
    sign_in @admin
    visit analytics_url
    assert_selector "h1", text: "Analytics"
  end

  test "regular user cannot visit analytics page" do
    sign_in @user
    visit analytics_url
    assert_text "You are not authorized to access this page"
    assert_current_path root_path
  end

  test "visiting the privacy page" do
    visit privacy_url
    assert_selector "h1", text: "Privacy Policy"
  end

  test "visiting the terms page" do
    visit terms_url
    assert_selector "h1", text: "Terms of Service"
  end

  test "visiting the about page" do
    visit about_url
    assert_selector "h1", text: "About Us"
  end
end