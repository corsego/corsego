# frozen_string_literal: true

class CourseMailer < ApplicationMailer
  def approved(course)
    @course = course
    @status = @course.approved? ? 'approved' : 'not approved'
    mail(to: @course.user.email, subject: "Your course \"#{@course.title}\" has been #{@status}")
  end
end
