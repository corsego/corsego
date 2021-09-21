# frozen_string_literal: true

class CoursePolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.all
    end
  end

  def show?
    @record.published && @record.approved ||
      @user&.has_role?(:admin) ||
      @user.present? && @record.user == @user ||
      @user.present? && @record.bought(@user)
  end

  def student_or_admin?
    @user.has_role?(:admin) || @record.bought(@user)
  end

  def analytics?
    @user.has_role?(:admin) || @record.user == @user
  end

  def approve?
    @user.has_role?(:admin)
  end

  def new?
    @user.has_role?(:teacher)
  end

  def create?
    @user.has_role?(:teacher)
  end

  def destroy?
    @record.user == @user && @record.enrollments.none? ||
      @user.has_role?(:admin) && @record.enrollments.none?
  end

  # course wizard
  def edit?
    @record.user == @user
  end

  # views
  def owner?
    @record.user == @user
  end

  # views
  def admin_or_owner?
    @user.has_role?(:admin) || @record.user == @user
  end
end
