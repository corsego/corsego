# frozen_string_literal: true

# Notifies the course owner when their course is approved (or unapproved) by admin
class CourseApprovedNotifier < ApplicationNotifier
  deliver_by :database

  required_params :course

  notification_methods do
    def message
      status = params[:course].approved? ? 'approved' : 'not approved'
      "Your course \"#{params[:course].title}\" has been #{status}"
    end

    def url
      Rails.application.routes.url_helpers.course_path(params[:course])
    end
  end
end
