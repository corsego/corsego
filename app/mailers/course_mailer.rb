class CourseMailer < ApplicationMailer
  def approved(course)
    @course = course
    mail(to: @course.user.email, subject: "Your course #{@course} has been approved and is live now!")
  end

  def unapproved(course)
    @course = course
    mail(to: @course.user.email, subject: "Your course #{@course} has been rejected.")
  end
end
