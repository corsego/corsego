# frozen_string_literal: true

require 'test_helper'

class CourseTest < ActiveSupport::TestCase
  test 'course with all required fields is valid' do
    course = Course.new(
      title: 'Test Course Title',
      description: 'This is a valid description for the course.',
      marketing_description: 'Marketing description goes here',
      language: 'English',
      level: 'Beginner',
      price: 100,
      user: users(:teacher)
    )
    assert course.valid?, course.errors.full_messages.join(', ')
  end

  test 'course requires title' do
    course = Course.new(
      description: 'Description text',
      marketing_description: 'Marketing description',
      language: 'English',
      level: 'Beginner',
      price: 100,
      user: users(:teacher)
    )
    assert_not course.valid?
    assert_includes course.errors[:title], "can't be blank"
  end

  test 'course requires unique title' do
    existing = courses(:published_course)
    course = Course.new(
      title: existing.title,
      description: 'Description text',
      marketing_description: 'Marketing description',
      language: 'English',
      level: 'Beginner',
      price: 100,
      user: users(:teacher)
    )
    assert_not course.valid?
    assert_includes course.errors[:title], 'has already been taken'
  end

  test 'course title must be at most 70 characters' do
    course = Course.new(
      title: 'a' * 71,
      description: 'Description text here',
      marketing_description: 'Marketing description',
      language: 'English',
      level: 'Beginner',
      price: 100,
      user: users(:teacher)
    )
    assert_not course.valid?
    assert_includes course.errors[:title], 'is too long (maximum is 70 characters)'
  end

  test 'course requires description' do
    course = Course.new(
      title: 'Test Course',
      marketing_description: 'Marketing description',
      language: 'English',
      level: 'Beginner',
      price: 100,
      user: users(:teacher)
    )
    assert_not course.valid?
    assert_includes course.errors[:description], "can't be blank"
  end

  test 'course requires marketing_description' do
    course = Course.new(
      title: 'Test Course',
      description: 'Description text here',
      language: 'English',
      level: 'Beginner',
      price: 100,
      user: users(:teacher)
    )
    assert_not course.valid?
    assert_includes course.errors[:marketing_description], "can't be blank"
  end

  test 'course marketing_description must be at most 300 characters' do
    course = Course.new(
      title: 'Test Course',
      description: 'Description text here',
      marketing_description: 'a' * 301,
      language: 'English',
      level: 'Beginner',
      price: 100,
      user: users(:teacher)
    )
    assert_not course.valid?
    assert_includes course.errors[:marketing_description], 'is too long (maximum is 300 characters)'
  end

  test 'course price must be non-negative' do
    course = Course.new(
      title: 'Test Course',
      description: 'Description text here',
      marketing_description: 'Marketing description',
      language: 'English',
      level: 'Beginner',
      price: -100,
      user: users(:teacher)
    )
    assert_not course.valid?
    assert_includes course.errors[:price], 'must be greater than or equal to 0'
  end

  test 'course price must be less than 500000' do
    course = Course.new(
      title: 'Test Course',
      description: 'Description text here',
      marketing_description: 'Marketing description',
      language: 'English',
      level: 'Beginner',
      price: 500_001,
      user: users(:teacher)
    )
    assert_not course.valid?
    assert_includes course.errors[:price], 'must be less than 500000'
  end

  test 'to_s returns title' do
    course = courses(:published_course)
    assert_equal course.title, course.to_s
  end

  test 'published scope returns published courses' do
    published = Course.published
    assert_includes published, courses(:published_course)
    assert_not_includes published, courses(:unpublished_course)
  end

  test 'unpublished scope returns unpublished courses' do
    unpublished = Course.unpublished
    assert_includes unpublished, courses(:unpublished_course)
    assert_not_includes unpublished, courses(:published_course)
  end

  test 'approved scope returns approved courses' do
    approved = Course.approved
    assert_includes approved, courses(:published_course)
    assert_not_includes approved, courses(:unpublished_course)
  end

  test 'unapproved scope returns unapproved courses' do
    unapproved = Course.unapproved
    assert_includes unapproved, courses(:unpublished_course)
    assert_not_includes unapproved, courses(:published_course)
  end

  test 'bought returns true if user is enrolled' do
    course = courses(:published_course)
    student = users(:student)

    assert course.bought(student)
  end

  test 'bought returns false if user is not enrolled' do
    course = courses(:unpublished_course)
    student = users(:student)

    assert_not course.bought(student)
  end

  test 'belongs to user' do
    course = courses(:published_course)
    assert_equal users(:teacher), course.user
  end

  test 'has many chapters' do
    course = courses(:published_course)
    assert_respond_to course, :chapters
    assert_includes course.chapters, chapters(:chapter_one)
  end

  test 'has many lessons' do
    course = courses(:published_course)
    assert_respond_to course, :lessons
    assert_includes course.lessons, lessons(:lesson_one)
  end

  test 'has many enrollments' do
    course = courses(:published_course)
    assert_respond_to course, :enrollments
    assert_includes course.enrollments, enrollments(:student_enrollment)
  end

  test 'has many tags through course_tags' do
    course = courses(:published_course)
    assert_respond_to course, :tags
    assert_includes course.tags, tags(:ruby)
  end

  test 'languages returns array of language options' do
    languages = Course.languages
    assert_kind_of Array, languages
    assert_includes languages.map(&:first), :English
  end

  test 'levels returns array of level options' do
    levels = Course.levels
    assert_kind_of Array, levels
    assert_includes levels.map(&:first), :Beginner
  end

  test 'update_rating calculates average from enrollments' do
    course = courses(:published_course)
    enrollment = enrollments(:student_enrollment)
    enrollment.update(rating: 4, review: 'Great course!')
    course.update_rating

    assert_equal 4.0, course.average_rating
  end

  test 'calculate_income sums enrollment prices' do
    course = courses(:published_course)
    course.calculate_income

    assert_equal 9900, course.income
  end

  test 'progress returns percentage of lessons viewed' do
    course = courses(:published_course)
    student = users(:student)

    # Student hasn't viewed any lessons - with lessons_count > 0, returns 0.0
    initial_progress = course.progress(student)
    assert_equal 0.0, initial_progress

    # View one lesson (50% of 2 lessons)
    student.view_lesson(lessons(:lesson_one))
    assert_equal 50.0, course.progress(student)
  end
end
