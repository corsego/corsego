# frozen_string_literal: true

class ChartPolicy < ApplicationPolicy
  def users_per_day?
    @user.has_role?(:admin)
  end

  def enrollments_per_day?
    @user.has_role?(:admin)
  end

  def course_popularity?
    @user.has_role?(:admin)
  end

  def money_makers?
    @user.has_role?(:admin)
  end
end
