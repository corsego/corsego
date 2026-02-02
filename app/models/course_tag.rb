# frozen_string_literal: true

class CourseTag < ApplicationRecord
  belongs_to :course
  belongs_to :tag, counter_cache: true
  # Tag.find_each { |tag| Tag.reset_counters(tag.id, :course_tags) }

  def self.ransackable_attributes(_auth_object = nil)
    %w[course_id tag_id created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[course tag]
  end
end
