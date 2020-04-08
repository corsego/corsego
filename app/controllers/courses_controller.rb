class CoursesController < ApplicationController
  before_action :set_course, only: [:show, :edit, :update, :destroy]

  def index
    #if params[:title]
    #  @courses = Course.where('title ILIKE ?', "%#{params[:title]}%") #case-insensitive
    #else
    #  #@courses = Course.all
    #  
    #  #@q = Course.ransack(params[:q])
    #  #@courses = @q.result.includes(:user)
    #end

    #if current_user.has_role?(:admin)
    #  @ransack_courses = Course.ransack(params[:courses_search], search_key: :courses_search)
    #  @courses = @ransack_courses.result.includes(:user)
    #else
    #  redirect_to root_path, alert: 'You do not have access'
    #end

    @ransack_courses = Course.ransack(params[:courses_search], search_key: :courses_search)
    @courses = @ransack_courses.result.includes(:user)

  end

  def show
    @lessons = @course.lessons
  end

  def new
    @course = Course.new
    authorize @course
  end

  def edit
    authorize @course
  end

  def create
    @course = Course.new(course_params)
    authorize @course
    @course.user = current_user

    respond_to do |format|
      if @course.save
        format.html { redirect_to @course, notice: 'Course was successfully created.' }
        format.json { render :show, status: :created, location: @course }
      else
        format.html { render :new }
        format.json { render json: @course.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    authorize @course
    respond_to do |format|
      if @course.update(course_params)
        format.html { redirect_to @course, notice: 'Course was successfully updated.' }
        format.json { render :show, status: :ok, location: @course }
      else
        format.html { render :edit }
        format.json { render json: @course.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    authorize @course
    @course.destroy
    respond_to do |format|
      format.html { redirect_to courses_url, notice: 'Course was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    def set_course
      @course = Course.friendly.find(params[:id])
    end

    def course_params
      params.require(:course).permit(:title, :description, :short_description, :price, :language, :level)
    end
end
