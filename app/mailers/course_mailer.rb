# frozen_string_literal: true

class CourseMailer < ApplicationMailer
  def approved(course)
    @course = course
    mail(to: @course.user.email, subject: "Your course #{@course} approval status: #{@course.approved}")
  end
end
