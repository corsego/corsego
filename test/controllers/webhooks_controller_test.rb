# frozen_string_literal: true

require 'test_helper'

class WebhooksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @student = users(:student)
    @student.update!(stripe_customer_id: 'cus_test_student')
    @published_course = courses(:published_course)
    @webhook_secret = 'whsec_test_secret'

    # Clear any existing enrollments for the student in this course
    Enrollment.where(user: @student, course: @published_course).delete_all
  end

  def generate_stripe_signature(payload)
    timestamp = Time.now.to_i
    signature = Stripe::Webhook::Signature.compute_signature(
      timestamp,
      payload,
      @webhook_secret
    )
    "t=#{timestamp},v1=#{signature}"
  end

  test 'webhook rejects invalid signature' do
    Rails.application.credentials.stubs(:dig).with(:test, :stripe, :webhook).returns(@webhook_secret)

    payload = { type: 'checkout.session.completed' }.to_json

    post webhooks_create_url,
         params: payload,
         headers: {
           'Content-Type' => 'application/json',
           'HTTP_STRIPE_SIGNATURE' => 'invalid_signature'
         }

    assert_response :bad_request
  end

  test 'webhook handles customer.created event' do
    Rails.application.credentials.stubs(:dig).with(:test, :stripe, :webhook).returns(@webhook_secret)

    customer_payload = {
      id: 'evt_test_123',
      type: 'customer.created',
      data: {
        object: {
          id: 'cus_new_customer',
          email: @student.email
        }
      }
    }
    payload = customer_payload.to_json
    signature = generate_stripe_signature(payload)

    post webhooks_create_url,
         params: payload,
         headers: {
           'Content-Type' => 'application/json',
           'HTTP_STRIPE_SIGNATURE' => signature
         }

    assert_response :success
    @student.reload
    assert_equal 'cus_new_customer', @student.stripe_customer_id
  end

  test 'webhook handles checkout.session.completed event and creates enrollment' do
    Rails.application.credentials.stubs(:dig).with(:test, :stripe, :webhook).returns(@webhook_secret)

    # Stub Stripe session retrieval
    mock_line_item = OpenStruct.new(
      price: OpenStruct.new(product: @published_course.stripe_product_id),
      amount_total: 9900
    )
    mock_session = OpenStruct.new(
      id: 'cs_test_123',
      customer: 'cus_test_student',
      line_items: OpenStruct.new(data: [mock_line_item])
    )
    Stripe::Checkout::Session.stubs(:retrieve).returns(mock_session)

    checkout_payload = {
      id: 'evt_test_456',
      type: 'checkout.session.completed',
      data: {
        object: {
          id: 'cs_test_123',
          customer: 'cus_test_student'
        }
      }
    }
    payload = checkout_payload.to_json
    signature = generate_stripe_signature(payload)

    assert_difference 'Enrollment.count', 1 do
      post webhooks_create_url,
           params: payload,
           headers: {
             'Content-Type' => 'application/json',
             'HTTP_STRIPE_SIGNATURE' => signature
           }
    end

    assert_response :success
    enrollment = Enrollment.find_by(user: @student, course: @published_course)
    assert enrollment.present?
    assert_equal 9900, enrollment.price
  end

  test 'webhook is idempotent - does not create duplicate enrollment' do
    Rails.application.credentials.stubs(:dig).with(:test, :stripe, :webhook).returns(@webhook_secret)

    # Stub Stripe session retrieval
    mock_line_item = OpenStruct.new(
      price: OpenStruct.new(product: @published_course.stripe_product_id),
      amount_total: 9900
    )
    mock_session = OpenStruct.new(
      id: 'cs_test_123',
      customer: 'cus_test_student',
      line_items: OpenStruct.new(data: [mock_line_item])
    )
    Stripe::Checkout::Session.stubs(:retrieve).returns(mock_session)

    checkout_payload = {
      id: 'evt_test_456',
      type: 'checkout.session.completed',
      data: {
        object: {
          id: 'cs_test_123',
          customer: 'cus_test_student'
        }
      }
    }
    payload = checkout_payload.to_json
    signature = generate_stripe_signature(payload)

    # First webhook should create enrollment
    assert_difference 'Enrollment.count', 1 do
      post webhooks_create_url,
           params: payload,
           headers: {
             'Content-Type' => 'application/json',
             'HTTP_STRIPE_SIGNATURE' => signature
           }
    end

    # Generate new signature for second call (same payload)
    signature2 = generate_stripe_signature(payload)

    # Second webhook should NOT create another enrollment
    assert_no_difference 'Enrollment.count' do
      post webhooks_create_url,
           params: payload,
           headers: {
             'Content-Type' => 'application/json',
             'HTTP_STRIPE_SIGNATURE' => signature2
           }
    end

    assert_response :success
  end

  test 'webhook race condition - success URL and webhook both try to create enrollment' do
    Rails.application.credentials.stubs(:dig).with(:test, :stripe, :webhook).returns(@webhook_secret)

    mock_line_item = OpenStruct.new(
      price: OpenStruct.new(product: @published_course.stripe_product_id),
      amount_total: 9900
    )
    mock_session = OpenStruct.new(
      id: 'cs_test_123',
      customer: 'cus_test_student',
      line_items: OpenStruct.new(data: [mock_line_item])
    )
    Stripe::Checkout::Session.stubs(:retrieve).returns(mock_session)

    # Simulate success URL already created the enrollment
    existing_enrollment = Enrollment.create!(user: @student, course: @published_course, price: 9900)

    checkout_payload = {
      id: 'evt_test_456',
      type: 'checkout.session.completed',
      data: {
        object: {
          id: 'cs_test_123',
          customer: 'cus_test_student'
        }
      }
    }
    payload = checkout_payload.to_json
    signature = generate_stripe_signature(payload)

    # Webhook should NOT create duplicate enrollment
    assert_no_difference 'Enrollment.count' do
      post webhooks_create_url,
           params: payload,
           headers: {
             'Content-Type' => 'application/json',
             'HTTP_STRIPE_SIGNATURE' => signature
           }
    end

    assert_response :success
  end
end
