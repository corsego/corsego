# frozen_string_literal: true

class StaticPagesController < ApplicationController
  skip_before_action :authenticate_user!, only: %i[landing_page privacy_policy]

  def landing_page
    @courses = Course.published.approved.order(enrollments_count: :desc, created_at: :desc)
    @popular_tags = Tag.all.where.not(course_tags_count: 0).order(course_tags_count: :desc).limit(10)
  end

  def activity
    redirect_to root_path, alert: 'You are not authorized to access this page' unless current_user.has_role?(:admin)
    @pagy, @activities = pagy(PublicActivity::Activity.all.order(created_at: :desc))
  end

  def analytics
    redirect_to root_path, alert: 'You are not authorized to access this page' unless current_user.has_role?(:admin)
  end

  def privacy
  end

  def terms
  end

  def about
  end
end
