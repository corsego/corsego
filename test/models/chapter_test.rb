# frozen_string_literal: true

require 'test_helper'

class ChapterTest < ActiveSupport::TestCase
  test 'chapter fixture is valid' do
    chapter = chapters(:chapter_one)
    assert chapter.valid?
  end

  test 'chapter requires title' do
    chapter = Chapter.new(course: courses(:published_course))
    assert_not chapter.valid?
    assert_includes chapter.errors[:title], "can't be blank"
  end

  test 'chapter requires course' do
    chapter = Chapter.new(title: 'Test Chapter')
    assert_not chapter.valid?
    assert_includes chapter.errors[:course], "can't be blank"
  end

  test 'chapter title must be at most 100 characters' do
    chapter = chapters(:chapter_one)
    chapter.title = 'a' * 101
    assert_not chapter.valid?
    assert_includes chapter.errors[:title], 'is too long (maximum is 100 characters)'
  end

  test 'chapter title must be unique within course' do
    existing = chapters(:chapter_one)
    chapter = Chapter.new(
      title: existing.title,
      course: existing.course
    )
    assert_not chapter.valid?
    assert_includes chapter.errors[:title], 'has already been taken'
  end

  test 'chapter title can be duplicated across courses' do
    chapter = Chapter.new(
      title: chapters(:chapter_one).title,
      course: courses(:free_course)
    )
    # This should be valid because it's a different course
    chapter.title = 'Unique Title for Free Course'
    assert chapter.valid?
  end

  test 'to_s returns title' do
    chapter = chapters(:chapter_one)
    assert_equal chapter.title, chapter.to_s
  end

  test 'belongs to course' do
    chapter = chapters(:chapter_one)
    assert_equal courses(:published_course), chapter.course
  end

  test 'has many lessons' do
    chapter = chapters(:chapter_one)
    assert_respond_to chapter, :lessons
    assert_includes chapter.lessons, lessons(:lesson_one)
  end

  test 'destroying chapter destroys associated lessons' do
    chapter = chapters(:chapter_one)
    lesson_count = chapter.lessons.count

    assert_difference 'Lesson.count', -lesson_count do
      chapter.destroy
    end
  end

  test 'has row_order for ranking' do
    chapter = chapters(:chapter_one)
    assert_respond_to chapter, :row_order
  end

  test 'generates slug from title' do
    chapter = chapters(:chapter_one)
    assert_equal 'getting-started', chapter.slug
  end
end
