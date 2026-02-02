# frozen_string_literal: true

class CommentPolicy < ApplicationPolicy
  def create?
    return false unless @user

    course = @record.lesson.course
    course.user == @user ||
      @user.bought?(course) ||
      @user.has_role?(:admin)
  end

  def destroy?
    @record.lesson.course.user == @user ||
      @record.user == @user ||
      @user.has_role?(:admin)
  end
end
