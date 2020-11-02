class StaticPagesController < ApplicationController
  skip_before_action :authenticate_user!, only: [:landing_page, :privacy_policy]

  def landing_page
    @latest_good_reviews = Enrollment.reviewed.latest_good_reviews.limit(2)
    @latest = Course.latest.published.approved.limit(2)
    @top_rated = Course.top_rated.published.approved.limit(2)
    @popular = Course.popular.published.approved.limit(2)
    if current_user
      @learning_courses = Course.joins(:enrollments).where(enrollments: {user: current_user}).order(created_at: :desc).limit(2)
      @teaching_courses = current_user.courses.limit(2)
    end
    @popular_tags = Tag.all.where.not(course_tags_count: 0).order(course_tags_count: :desc).limit(10)
  end

  def activity
    if current_user.has_role?(:admin)
      @pagy, @activities = pagy(PublicActivity::Activity.all.order(created_at: :desc))
    else
      redirect_to root_path, alert: "You are not authorized to access this page"
    end
  end

  def analytics
    unless current_user.has_role?(:admin)
      redirect_to root_path, alert: "You are not authorized to access this page"
    end
  end

  def privacy
  end

  def terms
  end

  def about
  end
end
