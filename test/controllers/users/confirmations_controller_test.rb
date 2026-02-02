# frozen_string_literal: true

require 'test_helper'

class Users::ConfirmationsControllerTest < ActionDispatch::IntegrationTest
  test 'user is automatically signed in after confirming account' do
    # Create an unconfirmed user
    user = User.new(
      email: 'newuser@example.com',
      password: 'password123',
      password_confirmation: 'password123'
    )
    user.skip_confirmation_notification!
    user.save!

    # Ensure user is not confirmed
    assert_nil user.confirmed_at
    assert_not user.confirmed?

    # Generate a confirmation token
    token = user.confirmation_token

    # Visit the confirmation URL
    get user_confirmation_path(confirmation_token: token)

    # User should be redirected (signed in)
    assert_response :redirect

    # Reload user and verify they are now confirmed
    user.reload
    assert user.confirmed?
    assert_not_nil user.confirmed_at

    # Follow redirect and verify user is signed in
    follow_redirect!
    assert_response :success

    # Verify user is signed in by checking they can access authenticated content
    # The controller should have called sign_in, so current_user should be set
    assert controller.current_user.present?, 'User should be signed in after confirmation'
    assert_equal user.id, controller.current_user.id
  end

  test 'user with invalid confirmation token is not signed in' do
    get user_confirmation_path(confirmation_token: 'invalid_token')

    # User should not be signed in with invalid token
    assert_nil controller.current_user
  end

  test 'already confirmed user cannot reuse confirmation token' do
    user = users(:student)

    # Student fixture is already confirmed
    assert user.confirmed?

    # Try to confirm again with a fake token
    get user_confirmation_path(confirmation_token: 'any_token')

    # User should not be signed in via this invalid confirmation flow
    assert_nil controller.current_user
  end
end
