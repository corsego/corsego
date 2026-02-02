# frozen_string_literal: true

# Notifies the course owner when someone enrolls in their course
class NewEnrollmentNotifier < ApplicationNotifier
  deliver_by :database

  required_params :enrollment

  notification_methods do
    def message
      enrollment = params[:enrollment]
      "#{enrollment.user.email} enrolled in your course \"#{enrollment.course.title}\""
    end

    def url
      Rails.application.routes.url_helpers.course_path(params[:enrollment].course)
    end
  end
end
