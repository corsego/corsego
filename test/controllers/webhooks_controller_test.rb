# frozen_string_literal: true

require 'test_helper'

class WebhooksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @valid_payload = { type: 'checkout.session.completed' }.to_json
  end

  test 'returns bad request for invalid JSON payload' do
    Stripe::Webhook.stubs(:construct_event).raises(JSON::ParserError.new('Invalid JSON'))

    post webhooks_url, params: 'invalid json', headers: { 'Stripe-Signature' => 'test_sig' }

    assert_response :bad_request
    response_body = JSON.parse(response.body)
    assert_equal 'Invalid payload', response_body['error']
  end

  test 'returns unauthorized for invalid signature' do
    Stripe::Webhook.stubs(:construct_event).raises(
      Stripe::SignatureVerificationError.new('Invalid signature', 'test_sig')
    )

    post webhooks_url, params: @valid_payload, headers: { 'Stripe-Signature' => 'invalid_sig' }

    assert_response :unauthorized
    response_body = JSON.parse(response.body)
    assert_equal 'Invalid signature', response_body['error']
  end

  test 'processes valid webhook with correct signature' do
    event = OpenStruct.new(
      type: 'customer.created',
      data: OpenStruct.new(
        object: OpenStruct.new(
          id: 'cus_test123',
          email: 'test@example.com'
        )
      )
    )

    Stripe::Webhook.stubs(:construct_event).returns(event)

    post webhooks_url,
         params: @valid_payload,
         headers: { 'Stripe-Signature' => 'valid_sig' }

    assert_response :success
  end
end
