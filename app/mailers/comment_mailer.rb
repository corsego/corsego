# frozen_string_literal: true

class CommentMailer < ApplicationMailer
  def new_comment(comment)
    @comment = comment
    mail(to: @comment.lesson.course.user.email, subject: "New comment in #{@course}")
  end
end
