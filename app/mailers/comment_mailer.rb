# frozen_string_literal: true

class CommentMailer < ApplicationMailer
  def new_comment(comment)
    @comment = comment
    @course = @comment.lesson.course
    @lesson = @comment.lesson
    mail(to: @course.user.email, subject: "New comment on your course: #{@course.title}")
  end
end
