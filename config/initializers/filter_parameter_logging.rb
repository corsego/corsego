# Be sure to restart your server when you modify this file.

# Configure sensitive parameters which will be filtered from the log file.
Rails.application.config.filter_parameters += [
  :password,
  :password_confirmation,
  :token,
  :secret,
  :api_key,
  :access_token,
  :refresh_token,
  :stripe,
  :credentials,
  :authorization,
  :credit_card,
  :card_number,
  :cvv,
  :ssn
]
