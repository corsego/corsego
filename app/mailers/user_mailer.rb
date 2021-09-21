# frozen_string_literal: true

class UserMailer < ApplicationMailer
  def new_user(user)
    @user = user
    mail(
      to: User.with_role(:admin).distinct.pluck(:email),
      subject: "Corsego: #{@user.email} registred"
    )
    # email_address_with_name(@user.email, @user.username)
  end
end
