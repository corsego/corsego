# frozen_string_literal: true

require 'test_helper'

class CheckoutControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @student = users(:student)
    @student.update!(stripe_customer_id: 'cus_test_student')
    @published_course = courses(:published_course)
  end

  # CREATE
  test 'unauthenticated user cannot create checkout session' do
    post checkout_create_url, params: { id: @published_course.id }, xhr: true
    assert_response :unauthorized
  end

  test 'authenticated user can create checkout session' do
    sign_in @student

    # Stub Stripe Checkout Session creation
    mock_session = OpenStruct.new(id: 'cs_test_123')
    Stripe::Checkout::Session.stubs(:create).returns(mock_session)

    post checkout_create_url, params: { id: @published_course.id }, xhr: true
    assert_response :success
  end

  # SUCCESS
  test 'success without session_id redirects to root with alert' do
    sign_in @student

    get checkout_success_url
    assert_redirected_to root_path
    assert_equal 'Invalid checkout session.', flash[:alert]
  end

  test 'success with invalid session_id redirects to root with alert' do
    sign_in @student

    # Stub Stripe to raise an error for invalid session
    Stripe::Checkout::Session.stubs(:retrieve).raises(Stripe::InvalidRequestError.new('No such session', 'session_id'))

    get checkout_success_url, params: { session_id: 'cs_invalid_123' }
    assert_redirected_to root_path
    assert_equal 'Unable to verify payment. Please contact support if you were charged.', flash[:alert]
  end

  test 'success with unpaid session redirects to root with alert' do
    sign_in @student

    # Stub Stripe to return unpaid session
    mock_session = OpenStruct.new(
      id: 'cs_test_123',
      payment_status: 'unpaid',
      customer: 'cus_test_student'
    )
    Stripe::Checkout::Session.stubs(:retrieve).returns(mock_session)

    get checkout_success_url, params: { session_id: 'cs_test_123' }
    assert_redirected_to root_path
    assert_equal 'Payment was not completed.', flash[:alert]
  end

  test 'success with mismatched customer redirects to root with alert' do
    sign_in @student

    # Stub Stripe to return session with different customer
    mock_line_item = OpenStruct.new(price: OpenStruct.new(product: @published_course.stripe_product_id), amount_total: 9900)
    mock_session = OpenStruct.new(
      id: 'cs_test_123',
      payment_status: 'paid',
      customer: 'cus_different_user',
      line_items: OpenStruct.new(data: [mock_line_item])
    )
    Stripe::Checkout::Session.stubs(:retrieve).returns(mock_session)

    get checkout_success_url, params: { session_id: 'cs_test_123' }
    assert_redirected_to root_path
    assert_equal 'Session does not match current user.', flash[:alert]
  end

  test 'success with valid paid session creates enrollment and redirects to course' do
    sign_in @student

    mock_line_item = OpenStruct.new(
      price: OpenStruct.new(product: @published_course.stripe_product_id),
      amount_total: 9900
    )
    mock_session = OpenStruct.new(
      id: 'cs_test_123',
      payment_status: 'paid',
      customer: 'cus_test_student',
      line_items: OpenStruct.new(data: [mock_line_item])
    )
    Stripe::Checkout::Session.stubs(:retrieve).returns(mock_session)

    # Remove any existing enrollment
    Enrollment.where(user: @student, course: @published_course).delete_all

    assert_difference 'Enrollment.count', 1 do
      get checkout_success_url, params: { session_id: 'cs_test_123' }
    end

    assert_redirected_to course_path(@published_course)
    assert_equal 'Payment successful! You are now enrolled in the course.', flash[:notice]

    enrollment = Enrollment.find_by(user: @student, course: @published_course)
    assert_equal 9900, enrollment.price
  end

  test 'success is idempotent - does not create duplicate enrollments' do
    sign_in @student

    mock_line_item = OpenStruct.new(
      price: OpenStruct.new(product: @published_course.stripe_product_id),
      amount_total: 9900
    )
    mock_session = OpenStruct.new(
      id: 'cs_test_123',
      payment_status: 'paid',
      customer: 'cus_test_student',
      line_items: OpenStruct.new(data: [mock_line_item])
    )
    Stripe::Checkout::Session.stubs(:retrieve).returns(mock_session)

    # Remove any existing enrollment first
    Enrollment.where(user: @student, course: @published_course).delete_all

    # First request should create enrollment
    assert_difference 'Enrollment.count', 1 do
      get checkout_success_url, params: { session_id: 'cs_test_123' }
    end

    # Second request should NOT create another enrollment
    assert_no_difference 'Enrollment.count' do
      get checkout_success_url, params: { session_id: 'cs_test_123' }
    end

    assert_redirected_to course_path(@published_course)
  end
end
