# frozen_string_literal: true

# Define an application-wide content security policy
# For further information see the following documentation
# https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy

Rails.application.config.content_security_policy do |policy|
  policy.default_src :self, :https
  policy.font_src    :self, :https, :data, "cdnjs.cloudflare.com"
  policy.img_src     :self, :https, :data
  policy.object_src  :none
  policy.script_src  :self, "js.stripe.com", "cdnjs.cloudflare.com", "plausible.io", "www.googletagmanager.com"
  policy.style_src   :self, :unsafe_inline, "cdnjs.cloudflare.com"
  policy.frame_src   "player.vimeo.com", "www.youtube-nocookie.com", "www.loom.com"
  policy.connect_src :self, "plausible.io", "www.googletagmanager.com"

  if Rails.env.development?
    policy.connect_src :self, "http://localhost:3035", "ws://localhost:3035"
  end
end

# Use nonces for inline scripts (required for Turbo + CSP)
Rails.application.config.content_security_policy_nonce_generator = ->(_request) { SecureRandom.base64(16) }
Rails.application.config.content_security_policy_nonce_directives = %w[script-src]
