module CommentsHelper

  def like_button(comment)
    if current_user.liked? comment
      link_to "Unlike", like_comment_path(comment, "unlike"), class: "thumbs-up", method: :put, remote: :true
    else
      link_to "Like", like_comment_path(comment, "like"), class: "thumbs-up-hollow", method: :put, remote: :true
    end
  end

end
