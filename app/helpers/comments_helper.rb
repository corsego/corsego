module CommentsHelper

  def like_button(comment)
    if current_user.liked? comment
      link_to " ", like_comment_path(comment, "unlike"), class: "liked fas fa-thumbs-up", method: :patch, remote: :true
    else
      link_to " ", like_comment_path(comment, "like"), class: "like far fa-thumbs-up", method: :patch, remote: :true
    end
  end

end
