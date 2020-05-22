class ApplicationMailer < ActionMailer::Base
  #default from: 'support@corsego.herokuapp.com'
  default from: "Corsego <support@corsego.com>"
  layout 'mailer'
end
