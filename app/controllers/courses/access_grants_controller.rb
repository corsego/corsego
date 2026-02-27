# frozen_string_literal: true

module Courses
  class AccessGrantsController < ApplicationController
    before_action :set_course

    def new
      authorize @course, :grant_access?
    end

    def create
      authorize @course, :grant_access?

      email = access_grant_params[:email].to_s.strip.downcase
      if email.blank?
        redirect_to new_course_access_grant_path(@course), alert: "Email can't be blank."
        return
      end

      @user = User.find_by(email: email) || User.invite!({ email: email }, current_user)

      unless @user.persisted?
        redirect_to new_course_access_grant_path(@course), alert: "Could not find or invite user."
        return
      end

      enrollment, created = @user.enroll_in_course(@course, price: 0)

      if created
        EnrollmentMailer.student_enrollment(enrollment).deliver_later
        redirect_to course_path(@course), notice: "Access granted to #{email}."
      else
        redirect_to new_course_access_grant_path(@course), alert: "#{email} is already enrolled in this course."
      end
    end

    private

    def set_course
      @course = Course.friendly.find(params[:course_id])
    end

    def access_grant_params
      params.expect(access_grant: [:email])
    end
  end
end
