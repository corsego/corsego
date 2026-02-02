# frozen_string_literal: true

class CourseInvitationsController < ApplicationController
  before_action :set_course
  before_action :authorize_course_owner, except: [:accept]
  skip_before_action :authenticate_user!, only: [:accept]

  # GET /courses/:course_id/invitations
  # Shows the share modal/page with link, QR code, and email form
  def show
  end

  # PATCH /courses/:course_id/invitations/toggle
  # Enables or disables invite link sharing
  def toggle
    @course.generate_invite_token! if @course.invite_token.blank?

    if @course.invite_enabled?
      @course.update!(invite_enabled: false)
      redirect_to course_path(@course), notice: 'Invite link sharing disabled.'
    else
      @course.update!(invite_enabled: true)
      redirect_to course_path(@course), notice: 'Invite link sharing enabled.'
    end
  end

  # POST /courses/:course_id/invitations/regenerate_token
  # Generates a new invite token (invalidates old links)
  def regenerate_token
    @course.regenerate_invite_token!
    redirect_to course_invitations_path(@course), notice: 'Invite link regenerated. Old links no longer work.'
  end

  # POST /courses/:course_id/invitations/send_emails
  # Sends invitation emails to specified addresses
  def send_emails
    emails = params[:emails].to_s.split(/[\s,;]+/).map(&:strip).reject(&:blank?).uniq

    if emails.empty?
      redirect_to course_invitations_path(@course), alert: 'Please enter at least one email address.'
      return
    end

    @course.generate_invite_token! if @course.invite_token.blank?
    @course.update!(invite_enabled: true) unless @course.invite_enabled?

    emails.each do |email|
      CourseInvitationMailer.invite(
        course: @course,
        email: email,
        invited_by: current_user
      ).deliver_later
    end

    redirect_to course_invitations_path(@course), notice: "Invitation sent to #{emails.count} #{'recipient'.pluralize(emails.count)}."
  end

  # GET /courses/:course_id/invitations/accept?token=xxx
  # Handles the invite link - enrolls user or prompts sign up
  def accept
    token = params[:token]

    unless @course.valid_invite_token?(token)
      redirect_to course_path(@course), alert: 'Invalid or expired invite link.'
      return
    end

    if user_signed_in?
      accept_for_signed_in_user
    else
      # Store the invite info in session and redirect to sign up
      session[:pending_course_invite] = {
        course_id: @course.id,
        token: token
      }
      redirect_to new_user_registration_path, notice: 'Please sign up or sign in to accept the course invitation.'
    end
  end

  private

  def set_course
    @course = Course.friendly.find(params[:course_id])
  end

  def authorize_course_owner
    authorize @course, :owner?
  end

  def accept_for_signed_in_user
    if current_user == @course.user
      redirect_to course_path(@course), alert: 'You cannot enroll in your own course.'
      return
    end

    if current_user.bought?(@course)
      redirect_to course_path(@course), notice: 'You are already enrolled in this course.'
      return
    end

    enrollment = current_user.enrollments.create!(
      course: @course,
      price: 0,
      invited: true
    )

    EnrollmentMailer.student_enrollment(enrollment).deliver_later
    EnrollmentMailer.teacher_enrollment(enrollment).deliver_later

    redirect_to course_path(@course), notice: 'You have been enrolled in this course for free!'
  end
end
