class EnrollmentsController < ApplicationController
  before_action :set_enrollment, only: [:show, :edit, :update, :destroy]
  before_action :set_coruse, only: [:new, :create]

  def index
    @enrollments = Enrollment.all
  end

  def show
  end

  def new
    @enrollment = Enrollment.new
  end

  def edit
  end

  def create
    if @course.price > 0
      flash[:alert] = "You can not access paid courses yet."
      redirect_to new_course_enrollment_path(@course)
    else
      @enrollment = current_user.buy_course(@course)
      redirect_to course_path(@course), notice: "You are enrolled!"
    end
  end

  def update
    respond_to do |format|
      if @enrollment.update(enrollment_params)
        format.html { redirect_to @enrollment, notice: 'Enrollment was successfully updated.' }
        format.json { render :show, status: :ok, location: @enrollment }
      else
        format.html { render :edit }
        format.json { render json: @enrollment.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @enrollment.destroy
    respond_to do |format|
      format.html { redirect_to enrollments_url, notice: 'Enrollment was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    def set_coruse
      @course = Course.friendly.find(params[:course_id])
    end

    def set_enrollment
      @enrollment = Enrollment.find(params[:id])
    end

    def enrollment_params
      params.require(:enrollment).permit(:rating, :review)
    end
end
