class CommentPolicy < ApplicationPolicy
  def destroy?
    @record.lesson.course.user == @user ||
      @record.user == @user ||
      @user.has_role?(:admin)
  end
end
