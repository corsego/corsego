# Preview all emails at http://localhost:3000/rails/mailers/course_invitation_mailer
class CourseInvitationMailerPreview < ActionMailer::Preview
  def invite
    course = Course.where.not(invite_token: nil).first || Course.first
    course.update(invite_token: 'preview_token', invite_enabled: true) if course.invite_token.blank?

    CourseInvitationMailer.invite(
      course: course,
      email: 'preview@example.com',
      invited_by: course.user
    )
  end
end
