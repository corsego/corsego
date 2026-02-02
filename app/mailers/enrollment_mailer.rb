# frozen_string_literal: true

class EnrollmentMailer < ApplicationMailer
  def student_enrollment(enrollment)
    @enrollment = enrollment
    @course = @enrollment.course
    @student = @enrollment.user
    mail(to: @student.email, subject: "Welcome to #{@course.title}!")
  end

  def teacher_enrollment(enrollment)
    @enrollment = enrollment
    @course = @enrollment.course
    @student = @enrollment.user
    @teacher = @course.user
    mail(to: @teacher.email, subject: "New enrollment in #{@course.title}")
  end
end
