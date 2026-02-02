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

  def self.ransackable_attributes(_auth_object = nil)
    %w[name course_tags_count created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[course_tags courses]
  end
end
