# frozen_string_literal: true

module LessonsHelper
  # lessons/show active_lesson(lesson, @lesson)
  def active_lesson(lesson, current_lesson)
    # content_tag(:li, class: "#{'list-group-item-success' if lesson == current_lesson} list-group-item") do
    content_tag(:li, class: "#{lesson.eql?(current_lesson) ? 'list-group-item-success' : 'list-group-item-secondary'} list-group-item") do
      render 'lessons/lesson_student', lesson: lesson
    end
  end
end
