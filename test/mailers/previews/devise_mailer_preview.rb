# frozen_string_literal: true

# Preview Devise emails at http://localhost:3000/rails/mailers/devise_mailer
class DeviseMailerPreview < ActionMailer::Preview
  # /rails/mailers/devise_mailer/confirmation_instructions
  def confirmation_instructions
    Devise::Mailer.confirmation_instructions(User.first, 'faketoken')
  end

  # /rails/mailers/devise_mailer/reset_password_instructions
  def reset_password_instructions
    Devise::Mailer.reset_password_instructions(User.first, 'faketoken')
  end

  # /rails/mailers/devise_mailer/unlock_instructions
  def unlock_instructions
    Devise::Mailer.unlock_instructions(User.first, 'faketoken')
  end

  # /rails/mailers/devise_mailer/password_change
  def password_change
    Devise::Mailer.password_change(User.first)
  end

  # /rails/mailers/devise_mailer/email_changed
  def email_changed
    user = User.first
    # Devise passes the user and options hash
    Devise::Mailer.email_changed(user, {})
  end
end
