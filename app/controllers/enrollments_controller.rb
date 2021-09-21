# frozen_string_literal: true

class EnrollmentsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:certificate]
  before_action :set_enrollment, only: %i[show edit update destroy certificate]

  def index
    @ransack_path = enrollments_path
    @q = Enrollment.ransack(params[:q])
    @pagy, @enrollments = pagy(@q.result.includes(:user))
    authorize @enrollments
  end

  def teaching
    @ransack_path = teaching_enrollments_path
    @q = current_user.students.ransack(params[:q])
    @pagy, @enrollments = pagy(@q.result.includes(:user))
    render 'index'
  end

  def certificate
    authorize @enrollment, :certificate?
    respond_to do |format|
      format.pdf do
        render pdf: "#{@enrollment.course.title}, #{@enrollment.user.email}",
               page_size: 'A4',
               template: 'enrollments/certificate.pdf.haml'
      end
    end
  end

  def show
  end

  def edit
    authorize @enrollment
  end

  def create
    @course = Course.friendly.find(params[:course_id])
    if @course.price.positive?
      redirect_to course_path(@course), alert: 'The course is not free...'
    else
      @enrollment = current_user.buy_course(@course)
      EnrollmentMailer.student_enrollment(@enrollment).deliver_later
      EnrollmentMailer.teacher_enrollment(@enrollment).deliver_later
      redirect_to course_path(@course), notice: 'You are enrolled!'
    end
  end

  def update
    authorize @enrollment
    if @enrollment.update(enrollment_params)
      redirect_to @enrollment, notice: 'Enrollment was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    authorize @enrollment
    @enrollment.destroy
    redirect_to enrollments_url, notice: 'Enrollment was successfully destroyed.'
  end

  private

  def set_enrollment
    @enrollment = Enrollment.friendly.find(params[:id])
  end

  def enrollment_params
    params.require(:enrollment).permit(:rating, :review)
  end
end
