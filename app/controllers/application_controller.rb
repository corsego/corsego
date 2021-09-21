# frozen_string_literal: true

class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  protect_from_forgery

  after_action :user_activity, if: :user_signed_in?

  include Pundit
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
