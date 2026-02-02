# frozen_string_literal: true

ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
require 'rails/test_help'
require 'mocha/minitest'

# Stub Stripe API calls
module StripeTestHelper
  def stub_stripe_calls
    # Stub Stripe::Customer.create
    Stripe::Customer.stubs(:create).returns(
      OpenStruct.new(id: "cus_test_#{SecureRandom.hex(8)}")
    )

    # Stub Stripe::Product.create
    Stripe::Product.stubs(:create).returns(
      OpenStruct.new(id: "prod_test_#{SecureRandom.hex(8)}")
    )

    # Stub Stripe::Price.create
    Stripe::Price.stubs(:create).returns(
      OpenStruct.new(id: "price_test_#{SecureRandom.hex(8)}")
    )
  end
end

class ActiveSupport::TestCase
  parallelize(workers: :number_of_processors)
  fixtures :all
  include Devise::Test::IntegrationHelpers
  include StripeTestHelper

  setup do
    stub_stripe_calls
    # Disable PublicActivity tracking in tests
    PublicActivity.enabled = false
    # Suppress mail delivery
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = false
  end
end
