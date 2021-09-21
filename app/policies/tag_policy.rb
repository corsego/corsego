# frozen_string_literal: true

class TagPolicy < ApplicationPolicy
  def destroy?
    @user.present? && @user.has_role?(:admin)
  end
end
