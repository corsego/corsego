# frozen_string_literal: true

class ChartsController < ApplicationController
  def users_per_day
    render json: User.group_by_day(:created_at).count
  end

  def enrollments_per_day
    render json: Enrollment.group_by_day(:created_at).count
  end

  def course_popularity
    render json: Enrollment.joins(:course).group(:'courses.title').count
  end

  def money_makers
    render json: Enrollment.joins(:course).group(:'courses.title').sum(:price)
  end
end
