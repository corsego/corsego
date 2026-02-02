# frozen_string_literal: true

ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
require 'rails/test_help'
require 'mocha/minitest'
require 'webmock/minitest'

# Disable PublicActivity tracking globally for tests
PublicActivity.enabled = false

# Set a test Stripe API key (requests will be stubbed by WebMock anyway)
Stripe.api_key = 'sk_test_fake_key_for_testing'

# Allow localhost connections for test server, block external
WebMock.disable_net_connect!(allow_localhost: true)

# Stub Stripe API calls at HTTP level BEFORE fixtures load
# This ensures callbacks don't hit the real Stripe API during fixture creation
WebMock.stub_request(:any, /api\.stripe\.com/).to_return(
  status: 200,
  body: {
    id: 'obj_test_123',
    object: 'customer'
  }.to_json,
  headers: { 'Content-Type' => 'application/json' }
)

# Stub Shakapacker helpers to avoid asset compilation issues in tests
# This overrides the helpers at the module level before tests run
module Shakapacker
  module Helper
    def javascript_pack_tag(*names, **options)
      ''.html_safe
    end

    def stylesheet_pack_tag(*names, **options)
      ''.html_safe
    end
  end
end

class ActiveSupport::TestCase
  # parallelize(workers: :number_of_processors) # Disabled due to pg gem segfault with fork on macOS
  fixtures :all
  include Devise::Test::IntegrationHelpers

  setup do
    # Stub Stripe API calls (WebMock resets stubs between tests)
    stub_request(:any, /api\.stripe\.com/).to_return(
      status: 200,
      body: { id: 'obj_test_123', object: 'customer' }.to_json,
      headers: { 'Content-Type' => 'application/json' }
    )

    # Suppress mail delivery
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = false
  end
end
