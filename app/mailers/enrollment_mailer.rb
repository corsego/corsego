class EnrollmentMailer < ApplicationMailer

  def new_enrollment(enrollment)
    @enrollment = enrollment
    @course = @enrollment.course
    mail(to: @enrollment.user.email, subject: "You have enrolled to: #{@course}")
    #mail(to: @enrollment.course.user.email, subject: "You have a new student in: #{@course}")
  end

end
