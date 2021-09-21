# frozen_string_literal: true

class CoursesController < ApplicationController
  skip_before_action :authenticate_user!, only: %i[show index]
  before_action :set_course, only: %i[show edit update destroy approve analytics]
  before_action :set_tags, only: %i[index learning pending_review teaching unapproved]

  def index
    @ransack_path = courses_path
    @ransack_courses = Course.published.approved.ransack(params[:courses_search], search_key: :courses_search)
    @pagy, @courses = pagy(@ransack_courses.result.includes(:user, :course_tags, course_tags: :tag))
  end

  def learning
    @ransack_path = learning_courses_path
    @ransack_courses = Course.joins(:enrollments).where(enrollments: { user: current_user }).ransack(params[:courses_search], search_key: :courses_search)
    @pagy, @courses = pagy(@ransack_courses.result.includes(:user, :course_tags, course_tags: :tag))
    render 'index'
  end

  def pending_review
    @ransack_path = pending_review_courses_path
    @ransack_courses = Course.joins(:enrollments).merge(Enrollment.pending_review.where(user: current_user)).ransack(params[:courses_search], search_key: :courses_search)
    @pagy, @courses = pagy(@ransack_courses.result.includes(:user, :course_tags, course_tags: :tag))
    render 'index'
  end

  def teaching
    @ransack_path = teaching_courses_path
    @ransack_courses = Course.where(user: current_user).ransack(params[:courses_search], search_key: :courses_search)
    @pagy, @courses = pagy(@ransack_courses.result.includes(:user, :course_tags, course_tags: :tag))
    render 'index'
  end

  def unapproved
    @ransack_path = unapproved_courses_path
    @ransack_courses = Course.unapproved.published.ransack(params[:courses_search], search_key: :courses_search)
    @pagy, @courses = pagy(@ransack_courses.result.includes(:user, :course_tags, course_tags: :tag))
    render 'index'
  end

  def show
    authorize @course
    @chapters = @course.chapters.rank(:row_order).includes(:lessons, lessons: [:user_lessons])
    @reviews = @course.enrollments.reviewed
  end

  def analytics
    authorize @course, :analytics? # admin_or_owner
  end

  def approve
    authorize @course, :approve? # admin
    if @course.approved?
      @course.update(approved: false)
    else
      @course.update(approved: true)
    end
    CourseMailer.approved(@course).deliver_later
    redirect_to @course, notice: "Course approval: #{@course.approved}"
  end

  def new
    @course = Course.new
    authorize @course
  end

  def create
    @course = Course.new(course_params)
    authorize @course
    @course.marketing_description = 'Marketing Description'
    @course.description = 'Curriculum Description'
    @course.user = current_user

    if @course.save
      redirect_to course_course_wizard_index_path(@course), notice: 'Course was successfully created.'
    else
      render :new
    end
  end

  def destroy
    authorize @course
    if @course.destroy
      redirect_to teaching_courses_path, notice: 'Course was successfully destroyed.'
    else
      redirect_to @course, alert: 'Course has enrollments. Can not be destroyed.'
    end
  end

  private

  def set_tags
    @tags = Tag.all.where.not(course_tags_count: 0).order(course_tags_count: :desc)
  end

  def set_course
    @course = Course.friendly.find(params[:id])
  end

  def course_params
    params.require(:course).permit(:title)
  end
end
