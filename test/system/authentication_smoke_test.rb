# frozen_string_literal: true

require 'application_system_test_case'

class AuthenticationSmokeTest < ApplicationSystemTestCase
  setup do
    @user = users(:student)
  end

  test 'sign in page loads' do
    visit new_user_session_url
    assert_selector 'h2', text: 'Log in'
    assert_selector 'input[type="email"]'
    assert_selector 'input[type="password"]'
    assert_selector 'input[type="submit"][value="Log in"]'
  end

  test 'sign up page loads' do
    visit new_user_registration_url
    assert_selector 'h2', text: 'Sign up'
    assert_selector 'input[type="email"]'
    assert_selector 'input[type="password"]'
    assert_selector 'input[type="submit"][value="Sign up"]'
  end

  test 'forgot password page loads' do
    visit new_user_password_url
    assert_selector 'h2', text: 'Forgot your password?'
    assert_selector 'input[type="email"]'
    assert_selector 'input[type="submit"]'
  end

  test 'user can sign in with valid credentials' do
    visit new_user_session_url

    fill_in 'Email', with: @user.email
    fill_in 'Password', with: 'password'
    click_button 'Log in'

    assert_text 'Signed in successfully'
  end

  test 'user cannot sign in with invalid credentials' do
    visit new_user_session_url

    fill_in 'Email', with: @user.email
    fill_in 'Password', with: 'wrongpassword'
    click_button 'Log in'

    assert_text 'Invalid Email or password'
  end

  test 'user can sign out' do
    visit new_user_session_url
    fill_in 'Email', with: @user.email
    fill_in 'Password', with: 'password'
    click_button 'Log in'

    assert_text 'Signed in successfully'

    click_link 'Sign out'

    assert_text 'Signed out successfully'
  end

  test 'unauthenticated user is redirected from protected page' do
    visit users_url

    assert_current_path new_user_session_path
    assert_text 'You need to sign in or sign up before continuing'
  end
end
