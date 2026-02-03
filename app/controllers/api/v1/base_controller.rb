# frozen_string_literal: true

module Api
  module V1
    class BaseController < ActionController::API
      before_action :authenticate_api_user!

      private

      def authenticate_api_user!
        token = request.headers['Authorization']&.delete_prefix('Bearer ')
        @current_user = User.find_by(api_token: token) if token.present?

        render json: { error: 'Unauthorized. Provide a valid API token via Authorization: Bearer <token> header.' },
               status: :unauthorized unless @current_user
      end

      attr_reader :current_user

      def require_teacher!
        return if current_user.has_role?(:teacher)

        render json: { error: 'You must have the teacher role to perform this action.' }, status: :forbidden
      end

      def without_tracking
        was_enabled = PublicActivity.enabled?
        PublicActivity.enabled = false
        yield
      ensure
        PublicActivity.enabled = was_enabled
      end

      def find_owned_course!
        @course = current_user.courses.friendly.find(params[:course_id] || params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Course not found or you do not own it.' }, status: :not_found
      end
    end
  end
end
