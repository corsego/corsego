class EnrollmentsController < ApplicationController
  before_action :set_enrollment, only: [:show, :edit, :update, :destroy]

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
    @enrollment = Enrollment.new(enrollment_params)
    @enrollment.price = @enrollment.course.price

    respond_to do |format|
      if @enrollment.save
        format.html { redirect_to @enrollment, notice: 'Enrollment was successfully created.' }
        format.json { render :show, status: :created, location: @enrollment }
      else
        format.html { render :new }
        format.json { render json: @enrollment.errors, status: :unprocessable_entity }
      end
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
    def set_enrollment
      @enrollment = Enrollment.find(params[:id])
    end

    def enrollment_params
      params.require(:enrollment).permit(:course_id, :user_id, :rating, :review)
    end
end
