# frozen_string_literal: true

module Api
  module V1
    class AuthenticationController < ActionController::API
      def create
        user = User.find_by(email: params[:email])

        if user&.valid_password?(params[:password])
          user.regenerate_api_token if user.api_token.blank?
          render json: {
            api_token: user.api_token,
            email: user.email,
            name: user.name,
            roles: user.roles.pluck(:name)
          }
        else
          render json: { error: 'Invalid email or password.' }, status: :unauthorized
        end
      end
    end
  end
end
