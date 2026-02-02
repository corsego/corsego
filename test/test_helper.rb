# frozen_string_literal: true

ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
require 'rails/test_help'
require 'mocha/minitest'

# Disable PublicActivity tracking globally for tests
PublicActivity.enabled = false

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

# Stub Stripe API calls
module StripeTestHelper
  def stub_stripe_calls
    Stripe::Customer.stubs(:create).returns(
      OpenStruct.new(id: "cus_test_#{SecureRandom.hex(8)}")
    )
    Stripe::Product.stubs(:create).returns(
      OpenStruct.new(id: "prod_test_#{SecureRandom.hex(8)}")
    )
    Stripe::Price.stubs(:create).returns(
      OpenStruct.new(id: "price_test_#{SecureRandom.hex(8)}")
    )
  end
end

class ActiveSupport::TestCase
  # parallelize(workers: :number_of_processors) # Disabled due to pg gem segfault with fork on macOS
  fixtures :all
  include Devise::Test::IntegrationHelpers
  include StripeTestHelper

  setup do
    stub_stripe_calls
    # Suppress mail delivery
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = false
  end
end
