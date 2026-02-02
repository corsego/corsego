# frozen_string_literal: true

# Notifies admins when a course is published and waiting for approval
class CoursePendingReviewNotifier < ApplicationNotifier
  deliver_by :database

  required_params :course

  notification_methods do
    def message
      "Course \"#{params[:course].title}\" by #{params[:course].user.email} is waiting for review"
    end

    def url
      Rails.application.routes.url_helpers.course_path(params[:course])
    end
  end
end
