# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy
# For further information see the following documentation
# https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy

Rails.application.config.content_security_policy do |policy|
  policy.default_src :self
  policy.font_src    :self, :data
  policy.img_src     :self, :data, :https
  policy.object_src  :none
  policy.script_src  :self, "https://js.stripe.com"
  policy.style_src   :self, :unsafe_inline
  policy.frame_src   :self, "https://player.vimeo.com", "https://js.stripe.com", "https://hooks.stripe.com"
  policy.connect_src :self, "https://api.stripe.com"

  # If you are using webpack-dev-server then specify webpack-dev-server host
  if Rails.env.development?
    policy.script_src :self, "https://js.stripe.com", :unsafe_eval
    policy.connect_src :self, "https://api.stripe.com", "http://localhost:3035", "ws://localhost:3035"
  end
end

# If you are using UJS then enable automatic nonce generation
# Rails.application.config.content_security_policy_nonce_generator = -> request { SecureRandom.base64(16) }

# Set the nonce only to specific directives
# Rails.application.config.content_security_policy_nonce_directives = %w(script-src)

# Report CSP violations to a specified URI
# For further information see the following documentation:
# https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy-Report-Only
# Rails.application.config.content_security_policy_report_only = true
