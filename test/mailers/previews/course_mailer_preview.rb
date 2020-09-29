# Preview all emails at http://localhost:3000/rails/mailers/course_mailer
class CourseMailerPreview < ActionMailer::Preview
  def approved
    CourseMailer.approved(Course.first).deliver_now
  end

  def unapproved
    CourseMailer.unapproved(Course.first).deliver_now
  end
end
