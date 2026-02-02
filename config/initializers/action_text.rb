# frozen_string_literal: true

# ActionText content sanitization configuration
# Allow iframe for YouTube embeds and video/audio elements

Rails.application.config.after_initialize do
  if defined?(ActionText::ContentHelper)
    # Allow additional HTML tags
    ActionText::ContentHelper.allowed_tags = ActionText::ContentHelper.allowed_tags.to_a + %w[iframe video audio source]

    # Allow additional HTML attributes
    ActionText::ContentHelper.allowed_attributes = ActionText::ContentHelper.allowed_attributes.to_a + %w[style controls src frameborder allow allowfullscreen]
  end
end
