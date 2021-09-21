# frozen_string_literal: true

class EnrollmentPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.all
    end
  end

  def index?
    @user.has_role?(:admin)
  end

  def edit?
    @record.user == @user
  end

  def update?
    @record.user == @user
  end

  def destroy?
    @user.has_role?(:admin)
  end

  def certificate?
    # course has as many lessons as the user has viewed for this course
    @record.course.lessons_count == @record.course.user_lessons.where(user: @record.user).count
  end
end
