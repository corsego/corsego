# Preview all emails at http://localhost:3000/rails/mailers/enrollment_mailer
class EnrollmentMailerPreview < ActionMailer::Preview
  def student_enrollment
    EnrollmentMailer.student_enrollment(Enrollment.first).deliver_now
  end

  def teacher_enrollment
    EnrollmentMailer.teacher_enrollment(Enrollment.first).deliver_now
  end
end
