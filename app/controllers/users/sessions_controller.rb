# frozen_string_literal: true

module Users
  class SessionsController < Devise::SessionsController
    # Rate limit login attempts: 10 attempts per 3 minutes per IP
    rate_limit to: 10, within: 3.minutes, only: :create, by: -> { request.remote_ip }
  end
end
