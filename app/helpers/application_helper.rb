# frozen_string_literal: true

module ApplicationHelper
  include Pagy::Frontend

  def crud_label(key)
    case key
    when 'create'
      "<i class='fa fa-plus' aria-hidden='true'></i>".html_safe
    when 'update'
      "<i class='fa fa-pen' aria-hidden='true'></i>".html_safe
    when 'destroy'
      "<i class='fa fa-trash' aria-hidden='true'></i>".html_safe
    end
  end

  def model_label(model)
    case model
    when 'Course'
      "<i class='fa fa-graduation-cap' aria-hidden='true'></i>".html_safe
    when 'Lesson'
      "<i class='fa fa-check-square' aria-hidden='true'></i>".html_safe
    when 'Enrollment'
      "<i class='fa fa-lock-open' aria-hidden='true'></i>".html_safe
    when 'Comment'
      "<i class='fa fa-comment' aria-hidden='true'></i>".html_safe
    end
  end

  def boolean_label(value)
    case value
    when true
      content_tag(:span, value, class: 'badge text-bg-success')
    when false
      content_tag(:span, value, class: 'badge text-bg-danger')
    end
  end

  # link_to "homepage", root_path
  def active_link_to(name, path)
    is_active = current_page?(path)
    content_tag(:li, class: "#{'active fw-bold' if is_active} nav-item") do
      link_to name, path, class: 'nav-link', 'aria-current': (is_active ? 'page' : nil)
    end
  end

  # link_to root_path do "homepage"
  def long_active_link_to(path, &block)
    is_active = current_page?(path)
    content_tag(:li, class: "#{'active fw-bold' if is_active} nav-item") do
      link_to path, class: 'nav-link', 'aria-current': (is_active ? 'page' : nil), &block
    end
  end
end
