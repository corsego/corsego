class ApplicationMailer < ActionMailer::Base
  default from: 'support@corsego.herokuapp.com'
  layout 'mailer'
end
