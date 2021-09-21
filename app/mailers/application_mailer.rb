# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  # default from: 'hello@corsego.com'
  default from: 'Corsego <hello@corsego.com>'
  layout 'mailer'
end
