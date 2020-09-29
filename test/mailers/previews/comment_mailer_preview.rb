# Preview all emails at http://localhost:3000/rails/mailers/comment_mailer
class CommentMailerPreview < ActionMailer::Preview
  # /rails/mailers/comment_mailer/new_comment
  def new_comment
    CommentMailer.new_comment(Comment.first).deliver_now
  end
end
