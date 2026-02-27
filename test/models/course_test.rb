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

  test 'update_stripe_price archives old price when price changes' do
    course = courses(:published_course)
    old_price_id = course.stripe_price_id

    # Stub Stripe Price.create to return a new price
    new_price_response = { id: 'price_new_999', object: 'price' }
    stub_request(:post, 'https://api.stripe.com/v1/prices')
      .to_return(status: 200, body: new_price_response.to_json, headers: { 'Content-Type' => 'application/json' })

    # Stub Stripe Price.update for archiving the old price
    archive_request = stub_request(:post, "https://api.stripe.com/v1/prices/#{old_price_id}")
      .with(body: hash_including('active' => 'false'))
      .to_return(status: 200, body: { id: old_price_id, active: false }.to_json, headers: { 'Content-Type' => 'application/json' })

    # Use save with validate: false to bypass ActionText validations
    course.price = 19900
    course.save!(validate: false)

    assert_requested archive_request
  end

  test 'avatar rejects non-image file with spoofed content type' do
    course = courses(:published_course)

    # Create a file that claims to be a PNG but contains text
    fake_image = StringIO.new("This is not a real image file, just plain text")
    course.avatar.attach(
      io: fake_image,
      filename: 'malicious.png',
      content_type: 'image/png'
    )

    assert_not course.valid?
    assert course.errors[:avatar].any?, "Expected avatar validation errors for non-processable file"
  end

  test 'avatar accepts valid image file' do
    course = courses(:published_course)

    # Create a minimal valid PNG (1x1 pixel)
    png_data = "\x89PNG\r\n\x1A\n" \
               "\x00\x00\x00\rIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x02\x00\x00\x00\x90wS\xDE" \
               "\x00\x00\x00\x0CIDAT\x08\xD7c\xF8\x0F\x00\x00\x01\x01\x00\x05\x18\xD8N" \
               "\x00\x00\x00\x00IEND\xAEB`\x82"
    valid_image = StringIO.new(png_data.dup.force_encoding('BINARY'))
    course.avatar.attach(
      io: valid_image,
      filename: 'valid.png',
      content_type: 'image/png'
    )

    course.valid?
    assert course.errors[:avatar].empty?, "Expected no avatar errors for valid PNG: #{course.errors[:avatar].join(', ')}"
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
