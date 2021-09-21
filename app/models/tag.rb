# frozen_string_literal: true

class Tag < ApplicationRecord
  has_many :course_tags, dependent: :destroy
  has_many :courses, through: :course_tags

  validates :name, length: { minimum: 1, maximum: 25 }, uniqueness: true

  def to_s
    name
  end

  def popular_name
    "#{name}: #{course_tags_count}"
  end
end
