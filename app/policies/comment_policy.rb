# frozen_string_literal: true

class CommentPolicy < ApplicationPolicy
  def create?
    @record.lesson.course.user == @user ||
      @record.lesson.course.bought(@user) ||
      @user.has_role?(:admin)
  end

  def destroy?
    @record.lesson.course.user == @user ||
      @record.user == @user ||
      @user.has_role?(:admin)
  end
end
