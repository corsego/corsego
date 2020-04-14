class HomeController < ApplicationController
  skip_before_action :authenticate_user!, :only => [:index]
  def index
    @latest_good_reviews = Enrollment.reviewed.latest_good_reviews
    @latest = Course.latest.published.approved
    @top_rated = Course.top_rated.published.approved
    @popular = Course.popular.published.approved
    @purchased_courses = Course.joins(:enrollments).where(enrollments: {user: current_user}).order(created_at: :desc).limit(3)
  end
  
  def activity
    if current_user.has_role?(:admin)
      @pagy, @activities = pagy(PublicActivity::Activity.all.order(created_at: :desc))
    else
      redirect_to root_path, alert: "You are not authorized to access this page"
    end
  end

  def analytics
    if current_user.has_role?(:admin)
      #@users = User.all
      #@enrollments = Enrollment.all
      #@courses = Course.all
    else
      redirect_to root_path, alert: "You are not authorized to access this page"
    end
  end

end
