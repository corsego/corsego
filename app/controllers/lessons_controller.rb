# frozen_string_literal: true

class LessonsController < ApplicationController
  before_action :set_lesson, only: %i[show edit update destroy]

  def sort
    @course = Course.friendly.find(params[:course_id])
    lesson = Lesson.friendly.find(params[:lesson_id])
    authorize lesson, :edit?
    lesson.update(lesson_params)
    render body: nil
  end

  def show
    authorize @lesson
    current_user.view_lesson(@lesson)
    @chapters = @course.chapters.rank(:row_order).includes(:lessons, lessons: [:user_lessons])
    @comment = Comment.new
    @comments = @lesson.comments.order(created_at: :desc)
  end

  def new
    @lesson = Lesson.new
    @course = Course.friendly.find(params[:course_id])
    @lesson.course_id = @course.id # for authorization
    authorize @lesson
  end

  def create
    @lesson = Lesson.new(lesson_params)
    @course = Course.friendly.find(params[:course_id])
    @lesson.course_id = @course.id

    authorize @lesson
    if @lesson.save
      redirect_to course_lesson_path(@course, @lesson, anchor: 'current_lesson'), notice: 'Lesson was successfully created.'
    else
      render :new
    end
  end

  def edit
    authorize @lesson
  end

  def update
    authorize @lesson
    if @lesson.update(lesson_params)
      redirect_to course_lesson_path(@course, @lesson, anchor: 'current_lesson'), notice: 'Lesson was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    authorize @lesson
    @lesson.destroy
    redirect_to course_path(@course), notice: 'Lesson was successfully destroyed.'
  end

  private

  def set_lesson
    @course = Course.friendly.find(params[:course_id])
    @lesson = Lesson.friendly.find(params[:id])
  end

  def lesson_params
    params.require(:lesson).permit(:title, :content, :row_order_position, :chapter_id, :vimeo)
  end
end
