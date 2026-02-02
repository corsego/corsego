# frozen_string_literal: true

require 'test_helper'

class CheckoutControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @admin = users(:admin)
    @teacher = users(:teacher)
    @student = users(:student)
    @another_teacher = users(:another_teacher)
    @published_course = courses(:published_course)
    @unpublished_course = courses(:unpublished_course)

    # Stub Stripe Checkout Session create
    @mock_session = OpenStruct.new(id: 'cs_test_123', url: 'https://checkout.stripe.com/test')
    Stripe::Checkout::Session.stubs(:create).returns(@mock_session)
  end

  # CREATE
  test 'unauthenticated user cannot create checkout session' do
    post checkout_create_url(id: @published_course.id), as: :js
    assert_response :unauthorized
  end

  test 'authenticated user can create checkout session for published course' do
    sign_in @another_teacher

    post checkout_create_url(id: @published_course.id), as: :js
    assert_response :success
  end

  test 'user cannot create checkout session for unpublished course' do
    sign_in @another_teacher

    post checkout_create_url(id: @unpublished_course.id), as: :js
    # Should be redirected by Pundit authorization failure
    assert_response :redirect
  end

  test 'already enrolled user cannot create checkout session' do
    sign_in @student

    post checkout_create_url(id: @published_course.id), as: :js
    assert_response :unprocessable_entity

    response_body = JSON.parse(response.body)
    assert_equal 'Already enrolled', response_body['error']
  end

  test 'course owner can still access checkout for their own course' do
    # This tests that authorization passes for course owner
    # In practice, they shouldn't need to buy their own course
    sign_in @teacher

    # The teacher owns this course and should pass authorization
    # but may fail on enrollment check if they're somehow enrolled
    post checkout_create_url(id: @published_course.id), as: :js
    # Should succeed since teacher is not enrolled
    assert_response :success
  end
end
