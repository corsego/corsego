# frozen_string_literal: true

module Users
  class PasswordsController < Devise::PasswordsController
    # Rate limit password reset requests: 5 attempts per 15 minutes per IP
    rate_limit to: 5, within: 15.minutes, only: :create, by: -> { request.remote_ip }
  end
end
