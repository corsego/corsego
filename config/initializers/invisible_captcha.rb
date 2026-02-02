# frozen_string_literal: true

InvisibleCaptcha.setup do |config|
  # Custom honeypot field name (randomized by default)
  # config.honeypots = ['foo', 'bar']

  # Minimum time (in seconds) for form submission
  config.timestamp_threshold = 2

  # Flash message when form submitted too fast
  config.timestamp_error_message = 'Please wait a moment before submitting.'

  # Sentence displayed in the honeypot field (for accessibility)
  config.visual_honeypots = false

  # Disable timestamp check in test environment (tests submit forms immediately)
  config.timestamp_enabled = !Rails.env.test?
end
