# frozen_string_literal: true

class CourseTag < ApplicationRecord
  belongs_to :course
  belongs_to :tag, counter_cache: true
  # Tag.find_each { |tag| Tag.reset_counters(tag.id, :course_tags) }
end
