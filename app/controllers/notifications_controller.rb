# frozen_string_literal: true

class NotificationsController < ApplicationController
  before_action :set_notification, only: %i[show]

  def index
    @notifications = current_user.notifications.includes(:event).newest_first
  end

  def show
    @notification.mark_as_read!
    redirect_to @notification.url || notifications_path
  end

  def mark_all_as_read
    current_user.notifications.mark_as_read!
    redirect_to notifications_path, notice: 'All notifications marked as read'
  end

  private

  def set_notification
    @notification = current_user.notifications.find(params[:id])
  end
end
