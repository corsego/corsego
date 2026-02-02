# frozen_string_literal: true

require 'test_helper'

class CourseTagTest < ActiveSupport::TestCase
  test 'course_tag fixture is valid' do
    course_tag = course_tags(:published_ruby)
    assert course_tag.valid?
  end

  test 'belongs to course' do
    course_tag = course_tags(:published_ruby)
    assert_equal courses(:published_course), course_tag.course
  end

  test 'belongs to tag' do
    course_tag = course_tags(:published_ruby)
    assert_equal tags(:ruby), course_tag.tag
  end

  test 'creating course_tag increments tag course_tags_count' do
    tag = tags(:programming)
    initial_count = tag.course_tags_count

    CourseTag.create!(course: courses(:unpublished_course), tag: tag)
    tag.reload

    assert_equal initial_count + 1, tag.course_tags_count
  end

  test 'destroying course_tag decrements tag course_tags_count' do
    course_tag = course_tags(:published_ruby)
    tag = course_tag.tag
    initial_count = tag.course_tags_count

    course_tag.destroy
    tag.reload

    assert_equal initial_count - 1, tag.course_tags_count
  end
end
