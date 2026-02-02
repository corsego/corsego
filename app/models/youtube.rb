# frozen_string_literal: true

class Youtube
  include ActiveModel::Model
  include ActiveModel::Attributes
  include GlobalID::Identification
  include ActionText::Attachable

  # YouTube video IDs are 11 characters, alphanumeric with - and _
  VALID_ID_PATTERN = /\A[a-zA-Z0-9_-]{11}\z/

  attribute :id

  validates :id, format: { with: VALID_ID_PATTERN, message: 'is not a valid YouTube video ID' }

  def self.find(id)
    youtube = new(id: id)
    youtube.valid? ? youtube : nil
  end

  def thumbnail_url
    return unless valid?

    "https://i3.ytimg.com/vi/#{id}/maxresdefault.jpg"
  end

  def to_trix_content_attachment_partial_path
    'youtubes/thumbnail'
  end
end
