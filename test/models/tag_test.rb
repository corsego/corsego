# frozen_string_literal: true

require 'test_helper'

class TagTest < ActiveSupport::TestCase
  test 'tag fixture is valid' do
    tag = tags(:ruby)
    assert tag.valid?
  end

  test 'tag requires name' do
    tag = Tag.new(name: nil)
    assert_not tag.valid?
    assert_includes tag.errors[:name], 'is too short (minimum is 1 character)'
  end

  test 'tag name must be at least 1 character' do
    tag = Tag.new(name: '')
    assert_not tag.valid?
    assert_includes tag.errors[:name], 'is too short (minimum is 1 character)'
  end

  test 'tag name must be at most 25 characters' do
    tag = Tag.new(name: 'a' * 26)
    assert_not tag.valid?
    assert_includes tag.errors[:name], 'is too long (maximum is 25 characters)'
  end

  test 'tag name must be unique' do
    existing = tags(:ruby)
    tag = Tag.new(name: existing.name)
    assert_not tag.valid?
    assert_includes tag.errors[:name], 'has already been taken'
  end

  test 'to_s returns name' do
    tag = tags(:ruby)
    assert_equal tag.name, tag.to_s
  end

  test 'has many course_tags' do
    tag = tags(:ruby)
    assert_respond_to tag, :course_tags
    assert_equal 1, tag.course_tags.count
  end

  test 'has many courses through course_tags' do
    tag = tags(:ruby)
    assert_respond_to tag, :courses
    assert_includes tag.courses, courses(:published_course)
  end

  test 'popular_name returns name with count' do
    tag = tags(:ruby)
    assert_equal 'Ruby: 1', tag.popular_name
  end

  test 'destroying tag destroys associated course_tags' do
    tag = tags(:ruby)
    course_tag_count = tag.course_tags.count

    assert_difference 'CourseTag.count', -course_tag_count do
      tag.destroy
    end
  end
end
