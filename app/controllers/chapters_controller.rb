class ChaptersController < ApplicationController
  before_action :set_chapter, only: [:edit, :update, :destroy]

  def new
    @chapter = Chapter.new
    @course = Course.friendly.find(params[:course_id])
  end

  def edit
  end

  def create
    @chapter = Chapter.new(chapter_params)
    @course = Course.friendly.find(params[:course_id])
    @chapter.course_id = @course.id

    if @chapter.save
      redirect_to course_path(@course), notice: 'Chapter was successfully created.'
    else
      render :new
    end
  end

  def update
    if @chapter.update(chapter_params)
      redirect_to course_path(@course), notice: 'Chapter was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    @chapter.destroy
    redirect_to course_path(@course), notice: 'Chapter was successfully destroyed.'
  end

  private
    def set_chapter
      @course = Course.friendly.find(params[:course_id])
      @chapter = Chapter.friendly.find(params[:id])
    end

    def chapter_params
      params.require(:chapter).permit(:row_order, :title)
    end
end
