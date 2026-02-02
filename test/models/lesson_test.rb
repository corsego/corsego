# frozen_string_literal: true

require 'test_helper'

class LessonTest < ActiveSupport::TestCase
  test 'lesson with all required fields is valid' do
    lesson = Lesson.new(
      title: 'Test Lesson',
      content: 'Test lesson content here',
      course: courses(:published_course),
      chapter: chapters(:chapter_one)
    )
    assert lesson.valid?, lesson.errors.full_messages.join(', ')
  end

  test 'lesson requires title' do
    lesson = Lesson.new(
      content: 'Content',
      course: courses(:published_course),
      chapter: chapters(:chapter_one)
    )
    assert_not lesson.valid?
    assert_includes lesson.errors[:title], "can't be blank"
  end

  test 'lesson requires content' do
    lesson = Lesson.new(
      title: 'Test Lesson',
      course: courses(:published_course),
      chapter: chapters(:chapter_one)
    )
    assert_not lesson.valid?
    assert_includes lesson.errors[:content], "can't be blank"
  end

  test 'lesson requires course' do
    lesson = Lesson.new(
      title: 'Test Lesson',
      content: 'Content',
      chapter: chapters(:chapter_one)
    )
    assert_not lesson.valid?
    assert_includes lesson.errors[:course], "can't be blank"
  end

  test 'lesson requires chapter' do
    lesson = Lesson.new(
      title: 'Test Lesson',
      content: 'Content',
      course: courses(:published_course)
    )
    assert_not lesson.valid?
    assert_includes lesson.errors[:chapter], "can't be blank"
  end

  test 'lesson title must be at most 100 characters' do
    lesson = Lesson.new(
      title: 'a' * 101,
      content: 'Content',
      course: courses(:published_course),
      chapter: chapters(:chapter_one)
    )
    assert_not lesson.valid?
    assert_includes lesson.errors[:title], 'is too long (maximum is 100 characters)'
  end

  test 'lesson title must be unique within course' do
    existing = lessons(:lesson_one)
    lesson = Lesson.new(
      title: existing.title,
      content: 'Content',
      course: existing.course,
      chapter: existing.chapter
    )
    assert_not lesson.valid?
    assert_includes lesson.errors[:title], 'has already been taken'
  end

  test 'to_s returns title' do
    lesson = lessons(:lesson_one)
    assert_equal lesson.title, lesson.to_s
  end

  test 'belongs to course' do
    lesson = lessons(:lesson_one)
    assert_equal courses(:published_course), lesson.course
  end

  test 'belongs to chapter' do
    lesson = lessons(:lesson_one)
    assert_equal chapters(:chapter_one), lesson.chapter
  end

  test 'has many user_lessons' do
    lesson = lessons(:lesson_one)
    assert_respond_to lesson, :user_lessons
  end

  test 'has many comments' do
    lesson = lessons(:lesson_one)
    assert_respond_to lesson, :comments
    assert_includes lesson.comments, comments(:student_comment)
  end

  test 'has row_order for ranking' do
    lesson = lessons(:lesson_one)
    assert_respond_to lesson, :row_order
  end

  test 'generates slug from title' do
    lesson = lessons(:lesson_one)
    assert_equal 'introduction-to-variables', lesson.slug
  end

  test 'impressions_count returns sum of user_lesson impressions' do
    lesson = lessons(:lesson_one)
    student = users(:student)

    student.view_lesson(lesson)
    student.view_lesson(lesson)

    assert_equal 2, lesson.impressions_count
  end

  test 'prev returns previous lesson in course' do
    lesson_two = lessons(:lesson_two)
    lesson_one = lessons(:lesson_one)

    assert_equal lesson_one, lesson_two.prev
  end

  test 'next returns next lesson in course' do
    lesson_one = lessons(:lesson_one)
    lesson_two = lessons(:lesson_two)

    assert_equal lesson_two, lesson_one.next
  end

  test 'prev returns nil for first lesson' do
    lesson_one = lessons(:lesson_one)
    assert_nil lesson_one.prev
  end

  test 'next returns nil for last lesson' do
    lesson_two = lessons(:lesson_two)
    assert_nil lesson_two.next
  end

  # VideoEmbed concern tests

  test 'has_video? returns false when video_url is blank' do
    lesson = lessons(:lesson_one)
    lesson.video_url = nil
    assert_not lesson.has_video?

    lesson.video_url = ''
    assert_not lesson.has_video?
  end

  test 'detects vimeo platform from full URL' do
    lesson = lessons(:lesson_one)
    lesson.video_url = 'https://vimeo.com/123456789'
    assert_equal :vimeo, lesson.video_platform
    assert_equal '123456789', lesson.video_id
    assert_equal 'https://player.vimeo.com/video/123456789', lesson.video_embed_url
    assert lesson.has_video?
  end

  test 'detects vimeo platform from player URL' do
    lesson = lessons(:lesson_one)
    lesson.video_url = 'https://player.vimeo.com/video/123456789'
    assert_equal :vimeo, lesson.video_platform
    assert_equal '123456789', lesson.video_id
    assert_equal 'https://player.vimeo.com/video/123456789', lesson.video_embed_url
  end

  test 'detects vimeo platform from legacy ID-only value' do
    lesson = lessons(:lesson_one)
    lesson.video_url = '123456789'
    assert_equal :vimeo, lesson.video_platform
    assert_equal '123456789', lesson.video_id
    assert_equal 'https://player.vimeo.com/video/123456789', lesson.video_embed_url
  end

  test 'detects youtube platform from watch URL' do
    lesson = lessons(:lesson_one)
    lesson.video_url = 'https://www.youtube.com/watch?v=dQw4w9WgXcQ'
    assert_equal :youtube, lesson.video_platform
    assert_equal 'dQw4w9WgXcQ', lesson.video_id
    assert_equal 'https://www.youtube.com/embed/dQw4w9WgXcQ', lesson.video_embed_url
    assert lesson.has_video?
  end

  test 'detects youtube platform from short URL' do
    lesson = lessons(:lesson_one)
    lesson.video_url = 'https://youtu.be/dQw4w9WgXcQ'
    assert_equal :youtube, lesson.video_platform
    assert_equal 'dQw4w9WgXcQ', lesson.video_id
    assert_equal 'https://www.youtube.com/embed/dQw4w9WgXcQ', lesson.video_embed_url
  end

  test 'detects youtube platform from embed URL' do
    lesson = lessons(:lesson_one)
    lesson.video_url = 'https://www.youtube.com/embed/dQw4w9WgXcQ'
    assert_equal :youtube, lesson.video_platform
    assert_equal 'dQw4w9WgXcQ', lesson.video_id
    assert_equal 'https://www.youtube.com/embed/dQw4w9WgXcQ', lesson.video_embed_url
  end

  test 'detects loom platform from share URL' do
    lesson = lessons(:lesson_one)
    lesson.video_url = 'https://www.loom.com/share/abc123def456'
    assert_equal :loom, lesson.video_platform
    assert_equal 'abc123def456', lesson.video_id
    assert_equal 'https://www.loom.com/embed/abc123def456', lesson.video_embed_url
    assert lesson.has_video?
  end

  test 'detects loom platform from embed URL' do
    lesson = lessons(:lesson_one)
    lesson.video_url = 'https://www.loom.com/embed/abc123def456'
    assert_equal :loom, lesson.video_platform
    assert_equal 'abc123def456', lesson.video_id
    assert_equal 'https://www.loom.com/embed/abc123def456', lesson.video_embed_url
  end

  test 'returns nil for unsupported video URLs' do
    lesson = lessons(:lesson_one)
    lesson.video_url = 'https://example.com/video/123'
    assert_nil lesson.video_platform
    assert_nil lesson.video_id
    assert_nil lesson.video_embed_url
    assert_not lesson.has_video?
  end

  test 'handles vimeo URLs without www prefix' do
    lesson = lessons(:lesson_one)
    lesson.video_url = 'https://vimeo.com/987654321'
    assert_equal :vimeo, lesson.video_platform
    assert_equal '987654321', lesson.video_id
  end

  test 'handles youtube URLs without www prefix' do
    lesson = lessons(:lesson_one)
    lesson.video_url = 'https://youtube.com/watch?v=abcdefghijk'
    assert_equal :youtube, lesson.video_platform
    assert_equal 'abcdefghijk', lesson.video_id
  end

  test 'handles loom URLs without www prefix' do
    lesson = lessons(:lesson_one)
    lesson.video_url = 'https://loom.com/share/xyz789abc123'
    assert_equal :loom, lesson.video_platform
    assert_equal 'xyz789abc123', lesson.video_id
  end
end
