class CommentsController < ApplicationController
  before_action :set_comment, only: %i[ destroy like ]
  def create
    @comment = Comment.new(comment_params)
    @course = Course.friendly.find(params[:course_id])
    @lesson = Lesson.friendly.find(params[:lesson_id])
    @comment.lesson = @lesson
    @comment.user = current_user

    if @comment.save
      CommentMailer.new_comment(@comment).deliver_later
      redirect_to course_lesson_path(@course, @lesson, anchor: "current_lesson"), notice: "Your comment was successfully added."
    else
      render "lessons/comments/new"
    end
  end

  def destroy
    @course = Course.friendly.find(params[:course_id])
    @lesson = Lesson.friendly.find(params[:lesson_id])
    authorize @comment
    @comment.destroy
    redirect_to course_lesson_path(@course, @lesson, anchor: "current_lesson"), notice: "Comment was successfully destroyed."
  end

  def like
    if params[:format] == 'like'
      @comment.liked_by current_user
      redirect_to request.referrer
    elsif params[:format] == 'unlike'
      @comment.unliked_by current_user
      redirect_to request.referrer
    end
  end

  private

  def comment_params
    params.require(:comment).permit(:content)
  end

  def set_comment
    @comment = Comment.find(params[:id])
  end
end
