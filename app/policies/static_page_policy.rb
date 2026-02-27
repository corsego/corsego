# frozen_string_literal: true

class StaticPagePolicy < ApplicationPolicy
  def activity?
    @user.has_role?(:admin)
  end

  def analytics?
    @user.has_role?(:admin)
  end
end
