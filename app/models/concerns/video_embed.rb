# frozen_string_literal: true

module VideoEmbed
  extend ActiveSupport::Concern

  VIMEO_REGEX = %r{
    (?:https?://)?
    (?:www\.)?
    (?:player\.)?
    vimeo\.com/
    (?:video/)?
    (\d+)
  }xi

  YOUTUBE_REGEX = %r{
    (?:https?://)?
    (?:www\.)?
    (?:youtube\.com/(?:watch\?v=|embed/)|youtu\.be/)
    ([a-zA-Z0-9_-]{11})
  }xi

  LOOM_REGEX = %r{
    (?:https?://)?
    (?:www\.)?
    loom\.com/
    (?:share|embed)/
    ([a-zA-Z0-9]+)
  }xi

  PLATFORM_CONFIGS = {
    vimeo: {
      regex: VIMEO_REGEX,
      embed_url: ->(id) { "https://player.vimeo.com/video/#{id}" }
    },
    youtube: {
      regex: YOUTUBE_REGEX,
      embed_url: ->(id) { "https://www.youtube.com/embed/#{id}" }
    },
    loom: {
      regex: LOOM_REGEX,
      embed_url: ->(id) { "https://www.loom.com/embed/#{id}" }
    }
  }.freeze

  def video_platform
    return nil if video_url.blank?

    PLATFORM_CONFIGS.each do |platform, config|
      return platform if video_url.match?(config[:regex])
    end

    # Support legacy Vimeo ID-only entries
    return :vimeo if video_url.match?(/^\d+$/)

    nil
  end

  def video_id
    return nil if video_url.blank?

    # Support legacy Vimeo ID-only entries
    return video_url if video_url.match?(/^\d+$/)

    PLATFORM_CONFIGS.each_value do |config|
      match = video_url.match(config[:regex])
      return match[1] if match
    end

    nil
  end

  def video_embed_url
    platform = video_platform
    id = video_id

    return nil if platform.nil? || id.nil?

    PLATFORM_CONFIGS[platform][:embed_url].call(id)
  end

  def has_video?
    video_embed_url.present?
  end
end
