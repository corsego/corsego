# frozen_string_literal: true

require 'test_helper'

class ChaptersControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @admin = users(:admin)
    @teacher = users(:teacher)
    @student = users(:student)
    @published_course = courses(:published_course)
    @chapter_one = chapters(:chapter_one)
  end

  # NEW
  test 'unauthenticated user cannot access new chapter form' do
    get new_course_chapter_url(@published_course)
    assert_redirected_to new_user_session_url
  end

  test 'course owner can access new chapter form' do
    sign_in @teacher
    get new_course_chapter_url(@published_course)
    assert_response :success
  end

  test 'non-owner cannot access new chapter form' do
    sign_in @student
    get new_course_chapter_url(@published_course)
    assert_redirected_to root_url
  end

  # CREATE
  test 'course owner can create chapter' do
    sign_in @teacher

    assert_difference 'Chapter.count', 1 do
      post course_chapters_url(@published_course), params: {
        chapter: { title: 'New Chapter' }
      }
    end

    assert_redirected_to course_path(@published_course)
  end

  test 'create chapter with invalid data renders new' do
    sign_in @teacher

    assert_no_difference 'Chapter.count' do
      post course_chapters_url(@published_course), params: {
        chapter: { title: '' }
      }
    end

    assert_response :success
  end

  test 'non-owner cannot create chapter' do
    sign_in @student

    assert_no_difference 'Chapter.count' do
      post course_chapters_url(@published_course), params: {
        chapter: { title: 'Hacked Chapter' }
      }
    end

    assert_redirected_to root_url
  end

  # EDIT
  test 'course owner can access edit chapter form' do
    sign_in @teacher
    get edit_course_chapter_url(@published_course, @chapter_one)
    assert_response :success
  end

  test 'non-owner can access edit chapter form but cannot update' do
    # Note: The edit action doesn't have explicit authorization
    # but the update action does
    sign_in @student
    get edit_course_chapter_url(@published_course, @chapter_one)
    assert_response :success
  end

  # UPDATE
  test 'course owner can update chapter' do
    sign_in @teacher

    patch course_chapter_url(@published_course, @chapter_one), params: {
      chapter: { title: 'Updated Chapter Title' }
    }

    @chapter_one.reload
    assert_equal 'Updated Chapter Title', @chapter_one.title
    assert_redirected_to course_path(@published_course)
  end

  test 'non-owner cannot update chapter' do
    sign_in @student
    original_title = @chapter_one.title

    patch course_chapter_url(@published_course, @chapter_one), params: {
      chapter: { title: 'Hacked Title' }
    }

    @chapter_one.reload
    assert_equal original_title, @chapter_one.title
    assert_redirected_to root_url
  end

  # DESTROY
  test 'course owner can destroy chapter' do
    sign_in @teacher

    assert_difference 'Chapter.count', -1 do
      delete course_chapter_url(@published_course, @chapter_one)
    end

    assert_redirected_to course_path(@published_course)
  end

  test 'non-owner cannot destroy chapter' do
    sign_in @student

    assert_no_difference 'Chapter.count' do
      delete course_chapter_url(@published_course, @chapter_one)
    end

    assert_redirected_to root_url
  end
end
