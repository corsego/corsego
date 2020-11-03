class CoursesController < ApplicationController
  skip_before_action :authenticate_user!, only: [:show, :index]
  before_action :set_course, only: [:show, :edit, :update, :destroy, :approve, :analytics]
  before_action :prepare_index, only: [:index, :learning, :pending_review, :teaching, :unapproved]

  def index
    @ransack_path = courses_path
    @ransack_courses = Course.published.approved.ransack(params[:courses_search], search_key: :courses_search)
  end

  def learning
    @ransack_path = learning_courses_path
    @ransack_courses = Course.joins(:enrollments).where(enrollments: {user: current_user}).ransack(params[:courses_search], search_key: :courses_search)
    render "index"
  end

  def pending_review
    @ransack_path = pending_review_courses_path
    @ransack_courses = Course.joins(:enrollments).merge(Enrollment.pending_review.where(user: current_user)).ransack(params[:courses_search], search_key: :courses_search)
    render "index"
  end

  def teaching
    @ransack_path = teaching_courses_path
    @ransack_courses = Course.where(user: current_user).ransack(params[:courses_search], search_key: :courses_search)
    render "index"
  end

  def unapproved
    @ransack_path = unapproved_courses_path
    @ransack_courses = Course.unapproved.published.ransack(params[:courses_search], search_key: :courses_search)
    render "index"
  end

  def approve
    authorize @course, :approve?
    if @course.approved?
      @course.update_attribute(:approved, false)
    else
      @course.update_attribute(:approved, true)
    end
    CourseMailer.approved(@course).deliver_later
    redirect_to @course, notice: "Course approved and visible!"
  end

  def analytics
    authorize @course, :owner?
  end

  def show
    authorize @course
    @lessons = @course.lessons.rank(:row_order)
    @chapters = @course.chapters.rank(:row_order)
    @enrollments_with_review = @course.enrollments.reviewed
  end

  def new
    @course = Course.new
    authorize @course
  end

  def create
    @course = Course.new(course_params)
    authorize @course
    @course.description = "Curriculum Description"
    @course.marketing_description = "Marketing Description"
    @course.user = current_user

    if @course.save
      redirect_to course_course_wizard_index_path(@course), notice: "Course was successfully created."
    else
      render :new
    end
  end

  def destroy
    authorize @course
    if @course.destroy
      redirect_to teaching_courses_path, notice: "Course was successfully destroyed."
    else
      redirect_to @course, alert: "Course has enrollments. Can not be destroyed."
    end
  end

  private

  def prepare_index
    @pagy, @courses = pagy(@ransack_courses.result.includes(:user, :course_tags, course_tags: :tag))
    @tags = Tag.all.where.not(course_tags_count: 0).order(course_tags_count: :desc)
  end

  def set_course
    @course = Course.friendly.find(params[:id])
  end

  def course_params
    params.require(:course).permit(:title)
  end
end
