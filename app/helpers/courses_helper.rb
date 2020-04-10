module CoursesHelper
  def enrollment_button(course)
    if current_user
      if course.user == current_user
        link_to "You created this course. View analytics", course_path(course)
      elsif course.enrollments.where(user: current_user).any?
        link_to "You bought this course. Keep learning", course_path(course)
      elsif course.price > 0
        link_to number_to_currency(course.price), new_course_enrollment_path(course), class: 'btn btn-success'
      else
        link_to "Free", new_course_enrollment_path(course), class: 'btn btn-success'
      end
      #logic to buy
    else
      link_to "Check price", course_path(course), class: "btn btn-md btn-success"
    end
  end

  def review_button(course)
    user_course = course.enrollments.where(user: current_user)
    if current_user
      if user_course.any?
        if user_course.pending_review.any?
          link_to 'Add a review', edit_enrollment_path(user_course.first)
        else
          link_to 'Thanks for reviewing! Your Review', enrollment_path(user_course.first)
        end
      end
    end
  end

end
