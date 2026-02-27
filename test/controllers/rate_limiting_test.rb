# frozen_string_literal: true

require 'test_helper'
require 'ostruct'

class RateLimitingTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @student = users(:student)
    @free_course = courses(:free_course)
    @published_course = courses(:published_course)
    @student.update!(stripe_customer_id: 'cus_test_student')

    # Clear rate limit cache before each test
    Rails.cache.clear
  end

  # Sessions controller rate limiting
  test 'login endpoint is accessible under rate limit' do
    post user_session_url, params: { user: { email: 'test@example.com', password: 'wrong' } }
    # Should get normal response (not rate limited)
    assert_not_equal 429, response.status
  end

  test 'login rate limit triggers after exceeded attempts' do
    # Sessions: 10 attempts per 3 minutes
    11.times do |i|
      post user_session_url, params: { user: { email: "test#{i}@example.com", password: 'wrong' } }
    end
    assert_response :too_many_requests
  end

  # Registrations controller rate limiting
  test 'registration endpoint is accessible under rate limit' do
    post user_registration_url, params: {
      user: { email: 'newuser@example.com', password: 'password123', password_confirmation: 'password123' }
    }
    # Should get normal response (not rate limited) - likely redirect or validation error
    assert_not_equal 429, response.status
  end

  test 'registration rate limit triggers after exceeded attempts' do
    # Registrations: 5 attempts per 15 minutes
    6.times do |i|
      post user_registration_url, params: {
        user: { email: "newuser#{i}@example.com", password: 'pass', password_confirmation: 'pass' }
      }
    end
    assert_response :too_many_requests
  end

  # Password reset rate limiting
  test 'password reset endpoint is accessible under rate limit' do
    post user_password_url, params: { user: { email: 'test@example.com' } }
    assert_not_equal 429, response.status
  end

  test 'password reset rate limit triggers after exceeded attempts' do
    # Password reset: 5 attempts per 15 minutes
    6.times do |i|
      post user_password_url, params: { user: { email: "test#{i}@example.com" } }
    end
    assert_response :too_many_requests
  end

  # Confirmation resend rate limiting
  test 'confirmation resend endpoint is accessible under rate limit' do
    post user_confirmation_url, params: { user: { email: 'test@example.com' } }
    assert_not_equal 429, response.status
  end

  test 'confirmation resend rate limit triggers after exceeded attempts' do
    # Confirmations: 5 attempts per 15 minutes
    6.times do |i|
      post user_confirmation_url, params: { user: { email: "test#{i}@example.com" } }
    end
    assert_response :too_many_requests
  end

  # Checkout rate limiting (requires authentication)
  test 'checkout endpoint is accessible under rate limit' do
    sign_in @student

    mock_session = OpenStruct.new(id: 'cs_test_123')
    Stripe::Checkout::Session.stubs(:create).returns(mock_session)

    post checkout_create_url, params: { id: @published_course.id }, xhr: true
    assert_not_equal 429, response.status
  end

  test 'checkout rate limit triggers after exceeded attempts' do
    sign_in @student

    mock_session = OpenStruct.new(id: 'cs_test_123')
    Stripe::Checkout::Session.stubs(:create).returns(mock_session)

    # Checkout: 10 attempts per 5 minutes per user
    11.times do
      post checkout_create_url, params: { id: @published_course.id }, xhr: true
    end
    assert_response :too_many_requests
  end

  # Comments rate limiting (requires authentication)
  test 'comment creation is accessible under rate limit' do
    sign_in @student
    lesson = @published_course.lessons.first

    post course_lesson_comments_url(@published_course, lesson), params: {
      comment: { content: 'Great lesson!' }
    }
    assert_not_equal 429, response.status
  end

  test 'comment rate limit triggers after exceeded attempts' do
    sign_in @student
    lesson = @published_course.lessons.first

    # Comments: 10 comments per 5 minutes per user
    11.times do |i|
      post course_lesson_comments_url(@published_course, lesson), params: {
        comment: { content: "Comment #{i}" }
      }
    end
    assert_response :too_many_requests
  end

  # Free enrollment rate limiting (requires authentication)
  test 'free enrollment is accessible under rate limit' do
    sign_in @student

    # Clean up any existing enrollment
    Enrollment.where(user: @student, course: @free_course).delete_all

    post course_enrollments_url(@free_course)
    assert_not_equal 429, response.status
  end

  # Certificate download rate limiting (IP-based, no auth required)
  test 'certificate download is accessible under rate limit' do
    enrollment = enrollments(:student_enrollment)

    # Mark all lessons as complete for certificate access
    @published_course.lessons.each do |lesson|
      UserLesson.find_or_create_by!(user: @student, lesson: lesson)
    end

    get certificate_enrollment_url(enrollment, format: :pdf)
    assert_not_equal 429, response.status
  end

  test 'certificate rate limit triggers after exceeded attempts' do
    enrollment = enrollments(:student_enrollment)

    # Mark all lessons as complete for certificate access
    @published_course.lessons.each do |lesson|
      UserLesson.find_or_create_by!(user: @student, lesson: lesson)
    end

    # Certificates: 20 requests per 5 minutes per IP
    21.times do
      get certificate_enrollment_url(enrollment, format: :pdf)
    end
    assert_response :too_many_requests
  end
end
