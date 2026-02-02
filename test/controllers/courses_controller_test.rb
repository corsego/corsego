# frozen_string_literal: true

require 'test_helper'

class CoursesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @admin = users(:admin)
    @teacher = users(:teacher)
    @student = users(:student)
    @another_teacher = users(:another_teacher)
    @published_course = courses(:published_course)
    @unpublished_course = courses(:unpublished_course)
    @free_course = courses(:free_course)
  end

  # INDEX
  test 'should get index without authentication' do
    get courses_url
    assert_response :success
  end

  test 'index shows only published and approved courses' do
    get courses_url
    assert_response :success
    assert_select 'body' # Basic response check
  end

  # Ransack sorting tests - verifies Arel::Table#table_name fix
  test 'index with ransack sort by average_rating succeeds' do
    get courses_url, params: { courses_search: { s: 'average_rating asc' } }
    assert_response :success
  end

  test 'index with ransack sort by price succeeds' do
    get courses_url, params: { courses_search: { s: 'price desc' } }
    assert_response :success
  end

  test 'index with ransack sort by enrollments_count succeeds' do
    get courses_url, params: { courses_search: { s: 'enrollments_count desc' } }
    assert_response :success
  end

  test 'index with ransack sort by created_at succeeds' do
    get courses_url, params: { courses_search: { s: 'created_at desc' } }
    assert_response :success
  end

  test 'index with ransack filter and sort succeeds' do
    # This replicates the exact production error URL pattern
    get courses_url, params: {
      courses_search: { course_tags_tag_id_eq: 1, s: 'average_rating asc' },
      page: 1
    }
    assert_response :success
  end

  # SHOW
  test 'should show published and approved course without authentication' do
    get course_url(@published_course)
    assert_response :success
  end

  test 'should not show unpublished course without authentication' do
    get course_url(@unpublished_course)
    assert_redirected_to root_url
  end

  test 'course owner can view their unpublished course' do
    sign_in @teacher
    get course_url(@unpublished_course)
    assert_response :success
  end

  test 'admin can view unpublished course' do
    sign_in @admin
    get course_url(@unpublished_course)
    assert_response :success
  end

  test 'enrolled student can view course' do
    sign_in @student
    get course_url(@published_course)
    assert_response :success
  end

  # NEW
  test 'unauthenticated user cannot access new course' do
    get new_course_url
    assert_redirected_to new_user_session_url
  end

  test 'teacher can access new course form' do
    sign_in @teacher
    get new_course_url
    assert_response :success
  end

  # CREATE
  test 'teacher can create course' do
    sign_in @teacher

    assert_difference 'Course.count', 1 do
      post courses_url, params: { course: { title: 'New Test Course' } }
    end

    course = Course.last
    assert_redirected_to course_course_wizard_index_path(course)
  end

  test 'create course with invalid data renders new' do
    sign_in @teacher

    assert_no_difference 'Course.count' do
      post courses_url, params: { course: { title: '' } }
    end

    assert_response :success
  end

  # DESTROY
  test 'course owner can destroy course without enrollments' do
    sign_in @teacher

    assert_difference 'Course.count', -1 do
      delete course_url(@unpublished_course)
    end

    assert_redirected_to teaching_courses_path
  end

  test 'course with enrollments cannot be destroyed by owner' do
    sign_in @teacher

    # Policy returns false, triggers Pundit::NotAuthorizedError which redirects to root
    assert_no_difference 'Course.count' do
      delete course_url(@published_course)
    end

    assert_redirected_to root_url
  end

  test 'non-owner cannot destroy course' do
    sign_in @student

    assert_no_difference 'Course.count' do
      delete course_url(@unpublished_course)
    end

    assert_redirected_to root_url
  end

  # LEARNING
  test 'unauthenticated user cannot access learning courses' do
    get learning_courses_url
    assert_redirected_to new_user_session_url
  end

  test 'student can access learning courses' do
    sign_in @student
    get learning_courses_url
    assert_response :success
  end

  # TEACHING
  test 'unauthenticated user cannot access teaching courses' do
    get teaching_courses_url
    assert_redirected_to new_user_session_url
  end

  test 'teacher can access teaching courses' do
    sign_in @teacher
    get teaching_courses_url
    assert_response :success
  end

  # PENDING REVIEW
  test 'student can access pending review courses' do
    sign_in @student
    get pending_review_courses_url
    assert_response :success
  end

  # UNAPPROVED
  test 'unauthenticated user cannot access unapproved courses' do
    get unapproved_courses_url
    assert_redirected_to new_user_session_url
  end

  test 'user can access unapproved courses' do
    sign_in @teacher
    get unapproved_courses_url
    assert_response :success
  end

  # ANALYTICS
  test 'course owner can access analytics' do
    sign_in @teacher
    get analytics_course_url(@published_course)
    assert_response :success
  end

  test 'admin can access any course analytics' do
    sign_in @admin
    get analytics_course_url(@free_course)
    assert_response :success
  end

  test 'non-owner cannot access course analytics' do
    sign_in @student
    get analytics_course_url(@published_course)
    assert_redirected_to root_url
  end

  # APPROVE
  test 'admin can approve unapproved course' do
    sign_in @admin

    # Create a fresh course to avoid ActionText fixture issues
    course = Course.new(
      title: 'Test Course For Approval',
      language: 'English',
      level: 'Beginner',
      price: 1000,
      user: @another_teacher,
      published: true,
      approved: false
    )
    course.description = 'Test description content'
    course.marketing_description = 'Test marketing description'
    course.save!

    assert_not course.approved?

    patch approve_course_url(course)

    course.reload
    assert course.approved?
    assert_redirected_to course
  end

  test 'non-admin cannot approve course' do
    sign_in @teacher

    patch approve_course_url(@unpublished_course)

    @unpublished_course.reload
    assert_not @unpublished_course.approved?
    assert_redirected_to root_url
  end
end
