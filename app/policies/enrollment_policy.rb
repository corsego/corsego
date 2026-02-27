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

  def show?
    @record.user == @user || @user.has_role?(:admin)
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
    # Public access — certificates are shared on LinkedIn/resumes.
    # Only require that the enrollment owner completed all lessons.
    @record.course.lessons_count == @record.course.user_lessons.where(user: @record.user).count
  end
end
