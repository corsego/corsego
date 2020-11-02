module CoursesHelper
  def enrollment_button(course)
    if current_user
      if course.user == current_user
        link_to course_path(course) do
          "You created this course " +
            number_to_currency(course.price)
        end
      elsif course.enrollments.where(user: current_user).any?
        render "courses/progress", course: course
      elsif course.price > 0
        link_to number_to_currency(course.price), new_course_enrollment_path(course), class: "btn btn-success"
      else
        link_to "Free", new_course_enrollment_path(course), class: "btn btn-success"
      end
    else
      link_to "Check price", new_course_enrollment_path(course), class: "btn btn-md btn-success"
    end
  end

  def review_button(course)
    user_course = course.enrollments.where(user: current_user)
    if current_user
      if user_course.any?
        if user_course.pending_review.any?
          link_to edit_enrollment_path(user_course.first) do
            "<i class='text-warning fa fa-star'></i>".html_safe + " " +
              "<i class='text-dark fa fa-question'></i>".html_safe + " " +
              "Add a review"
          end
        else
          link_to enrollment_path(user_course.first) do
            "<i class='text-warning fa fa-star'></i>".html_safe + " " +
              "<i class='text-success fa fa-check'></i>".html_safe + " " +
              "Thanks for reviewing!"
          end
        end
      end
    end
  end

  def certificate_button(course)
    user_course = course.enrollments.where(user: current_user)
    if current_user
      if user_course.any?
        if course.progress(current_user) == 100
          link_to certificate_enrollment_path(user_course.first, format: :pdf) do
            "<i class='text-danger fa fa-file-pdf'></i>".html_safe + " " +
              "Certificate of Completion"
          end
        else
          "Certificate available after completion"
        end
      end
    end
  end
end
