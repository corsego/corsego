module ApplicationHelper
  include Pagy::Frontend

  def crud_label(key)
    case key
      when "create"
        "<i class='fa fa-plus'></i>".html_safe
      when "update"
        "<i class='fa fa-pen'></i>".html_safe
      when "destroy"
        "<i class='fa fa-trash'></i>".html_safe
    end
  end

  def model_label(model)
    case model
      when "Course"
        "<i class='fa fa-graduation-cap'></i>".html_safe
      when "Lesson"
        "<i class='fa fa-check-square'></i>".html_safe
      when "Enrollment"
        "<i class='fa fa-lock-open'></i>".html_safe
      when "Comment"
        "<i class='fa fa-comment'></i>".html_safe
    end
  end

  def boolean_label(value)
    case value
      when true
        content_tag(:span, value, class: "badge badge-success")
      when false
        content_tag(:span, value, class: "badge badge-danger")
    end
  end

end
