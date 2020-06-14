class TagPolicy < ApplicationPolicy

  #def index?
  #  @user.has_role?(:admin)
  #end
  
  def destroy?
    @user.present? && @user.has_role?(:admin)
  end

end