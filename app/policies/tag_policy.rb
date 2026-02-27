# frozen_string_literal: true

class TagPolicy < ApplicationPolicy
  def create?
    @user.present? && @user.has_role?(:admin)
  end

  def destroy?
    @user.present? && @user.has_role?(:admin)
  end
end
