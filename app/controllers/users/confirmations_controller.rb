# frozen_string_literal: true

module Users
  class ConfirmationsController < Devise::ConfirmationsController
    # Rate limit confirmation resend requests: 5 attempts per 15 minutes per IP
    rate_limit to: 5, within: 15.minutes, only: :create, by: -> { request.remote_ip }

    private

    def after_confirmation_path_for(_resource_name, resource)
      sign_in(resource)
      root_path
    end
  end
end
