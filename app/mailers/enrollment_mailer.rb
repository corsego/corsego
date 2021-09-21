# frozen_string_literal: true

class EnrollmentMailer < ApplicationMailer
  def student_enrollment(enrollment)
    @enrollment = enrollment
    @course = @enrollment.course
    mail(to: @enrollment.user.email, subject: "You have enrolled to: #{@course}")
  end

  def teacher_enrollment(enrollment)
    @enrollment = enrollment
    @course = @enrollment.course
    mail(to: @enrollment.course.user.email, subject: "You have a new student in: #{@course}")
  end
end
