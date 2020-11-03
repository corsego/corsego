class Lesson < ApplicationRecord
  belongs_to :course, counter_cache: true
  belongs_to :chapter, counter_cache: true
  # Course.find_each { |course| Course.reset_counters(course.id, :lessons) }
  has_many :user_lessons, dependent: :destroy
  has_many :comments, dependent: :destroy

  validates :title, :content, :course, presence: true
  validates :title, length: {maximum: 100}
  validates_uniqueness_of :title, scope: :course_id

  has_rich_text :content
  has_one_attached :video
  validates :video,
    content_type: ["video/mp4"],
    size: {less_than: 50.megabytes, message: "size should be under 50 megabytes"}

  # has_one_attached :video_thumbnail
  # validates :video_thumbnail,
  #  content_type: ['image/png', 'image/jpg', 'image/jpeg'],
  #  size: { less_than: 500.kilobytes , message: 'size should be under 500 kilobytes' }
  # validates :video_thumbnail, presence: true, if: :video_present?
  # def video_present?
  #  self.video.present?
  # end

  extend FriendlyId
  friendly_id :title, use: :slugged

  include PublicActivity::Model
  tracked owner: proc { |controller, model| controller.current_user }

  include RankedModel
  ranks :row_order, with_same: :chapter_id

  def to_s
    title
  end

  def prev
    course.lessons.where("row_order < ?", row_order).order(:row_order).last
  end

  def impressions_count
    user_lessons.map(&:impressions).sum
  end

  def next
    course.lessons.where("row_order > ?", row_order).order(:row_order).first
  end

  def viewed(user)
    user_lessons.where(user: user).present?
  end
end
