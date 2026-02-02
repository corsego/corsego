# Preview all emails at http://localhost:3000/rails/mailers/course_mailer
class CourseMailerPreview < ActionMailer::Preview
  # Preview an approved course notification
  def approved
    CourseMailer.approved(Course.where(approved: true).first || Course.first)
  end

  # Preview a rejection notification (uses same mailer action with unapproved course)
  def not_approved
    course = Course.where(approved: false).first || Course.first
    # Temporarily set approved to false for preview if needed
    course.approved = false unless course.approved == false
    CourseMailer.approved(course)
  end
end
