# frozen_string_literal: true

class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  protect_from_forgery

  after_action :user_activity, if: :user_signed_in?

  include Pundit::Authorization
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  # save current_user using gem public_activity
  include PublicActivity::StoreController

  include Pagy::Backend

  before_action :set_global_variables
  def set_global_variables
    # navbar search
    @ransack_courses = Course.ransack(params[:courses_search], search_key: :courses_search)
  end

  private

  # devise
  def after_sign_in_path_for(resource)
    # Check for pending course invitation
    if session[:pending_course_invite].present?
      invite_data = session.delete(:pending_course_invite)
      course = Course.find_by(id: invite_data['course_id'] || invite_data[:course_id])
      token = invite_data['token'] || invite_data[:token]

      if course&.valid_invite_token?(token)
        return accept_course_invitations_path(course, token: token)
      end
    end

    user_path(resource)
  end

  def user_activity
    current_user.try :touch
  end

  # pundit
  def user_not_authorized
    flash[:alert] = 'You are not authorized to perform this action.'
    redirect_to(request.referer || root_path)
  end
end
