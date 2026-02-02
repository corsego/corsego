# frozen_string_literal: true

class CourseInvitationMailer < ApplicationMailer
  def invite(course:, email:, invited_by:)
    @course = course
    @invited_by = invited_by
    @invite_url = accept_course_invitations_url(@course, token: @course.invite_token)

    mail(
      to: email,
      subject: "You're invited to enroll in: #{@course.title}"
    )
  end
end
