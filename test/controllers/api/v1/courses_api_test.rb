# frozen_string_literal: true

require 'test_helper'

class Api::V1::CoursesApiTest < ActionDispatch::IntegrationTest
  setup do
    @teacher = users(:teacher)
    @student = users(:student)
    @published_course = courses(:published_course)
    @unpublished_course = courses(:unpublished_course)
    @chapter = chapters(:chapter_one)
    @lesson = lessons(:lesson_one)

    # ActionText rich text fields are not populated by YAML fixtures.
    # Create the ActionText records so validations pass on update.
    @unpublished_course.description = 'Advanced Ruby programming techniques'
    @unpublished_course.marketing_description = 'Take your Ruby skills to the next level'
    @unpublished_course.save!(validate: false)

    @lesson.content = 'Learn about variables in Ruby'
    @lesson.save!(validate: false)
  end

  # --- Authentication ---

  test 'authentication endpoint returns token for valid credentials' do
    post api_v1_auth_token_url, params: { email: @teacher.email, password: 'password' }, as: :json
    assert_response :success
    json = JSON.parse(response.body)
    assert json['api_token'].present?
    assert_equal @teacher.email, json['email']
  end

  test 'authentication endpoint rejects invalid credentials' do
    post api_v1_auth_token_url, params: { email: @teacher.email, password: 'wrong' }, as: :json
    assert_response :unauthorized
  end

  test 'API rejects requests without token' do
    get api_v1_courses_url, as: :json
    assert_response :unauthorized
  end

  # --- Courses ---

  test 'list courses returns teacher courses' do
    get api_v1_courses_url, headers: auth_headers(@teacher), as: :json
    assert_response :success
    json = JSON.parse(response.body)
    assert json.is_a?(Array)
    titles = json.map { |c| c['title'] }
    assert_includes titles, @published_course.title
  end

  test 'get course returns full details' do
    get api_v1_course_url(@published_course), headers: auth_headers(@teacher), as: :json
    assert_response :success
    json = JSON.parse(response.body)
    assert_equal @published_course.title, json['title']
    assert json['chapters'].is_a?(Array)
  end

  test 'create course with valid params' do
    assert_difference 'Course.count', 1 do
      post api_v1_courses_url, headers: auth_headers(@teacher), as: :json,
           params: { title: 'MCP Test Course', price: 2900, language: 'English', level: 'Beginner' }
    end
    assert_response :created
    json = JSON.parse(response.body)
    assert_equal 'MCP Test Course', json['title']
    assert_equal 2900, json['price']
  end

  test 'create course rejects duplicate title' do
    assert_no_difference 'Course.count' do
      post api_v1_courses_url, headers: auth_headers(@teacher), as: :json,
           params: { title: @published_course.title }
    end
    assert_response :unprocessable_entity
  end

  test 'update course' do
    patch api_v1_course_url(@unpublished_course), headers: auth_headers(@teacher), as: :json,
          params: { marketing_description: 'Updated via API' }
    assert_response :success
    json = JSON.parse(response.body)
    assert_equal 'Updated via API', json['marketing_description']
  end

  test 'cannot update course owned by another user' do
    patch api_v1_course_url(@published_course), headers: auth_headers(@student), as: :json,
          params: { title: 'Hacked' }
    assert_response :not_found
  end

  test 'publish course toggles published status' do
    assert_not @unpublished_course.published
    patch publish_api_v1_course_url(@unpublished_course), headers: auth_headers(@teacher), as: :json
    assert_response :success
    json = JSON.parse(response.body)
    assert json['published']
  end

  test 'delete course without enrollments' do
    assert_difference 'Course.count', -1 do
      delete api_v1_course_url(@unpublished_course), headers: auth_headers(@teacher), as: :json
    end
    assert_response :success
  end

  test 'cannot delete course with enrollments' do
    assert_no_difference 'Course.count' do
      delete api_v1_course_url(@published_course), headers: auth_headers(@teacher), as: :json
    end
    assert_response :unprocessable_entity
  end

  # --- Chapters ---

  test 'create chapter' do
    assert_difference 'Chapter.count', 1 do
      post api_v1_course_chapters_url(@published_course), headers: auth_headers(@teacher), as: :json,
           params: { title: 'New Chapter via API' }
    end
    assert_response :created
  end

  test 'update chapter' do
    patch api_v1_course_chapter_url(@published_course, @chapter), headers: auth_headers(@teacher), as: :json,
          params: { title: 'Updated Chapter Title' }
    assert_response :success
    json = JSON.parse(response.body)
    assert_equal 'Updated Chapter Title', json['title']
  end

  test 'delete chapter' do
    chapter = chapters(:chapter_advanced)
    assert_difference 'Chapter.count', -1 do
      delete api_v1_course_chapter_url(@unpublished_course, chapter), headers: auth_headers(@teacher), as: :json
    end
    assert_response :success
  end

  # --- Lessons ---

  test 'create lesson' do
    assert_difference 'Lesson.count', 1 do
      post api_v1_course_lessons_url(@published_course), headers: auth_headers(@teacher), as: :json,
           params: { title: 'New Lesson via API', content: 'Lesson content here', chapter_id: @chapter.id }
    end
    assert_response :created
  end

  test 'update lesson' do
    patch api_v1_course_lesson_url(@published_course, @lesson), headers: auth_headers(@teacher), as: :json,
          params: { title: 'Updated Lesson Title' }
    assert_response :success
    json = JSON.parse(response.body)
    assert_equal 'Updated Lesson Title', json['title']
  end

  test 'delete lesson' do
    lesson = lessons(:lesson_advanced)
    assert_difference 'Lesson.count', -1 do
      delete api_v1_course_lesson_url(@unpublished_course, lesson), headers: auth_headers(@teacher), as: :json
    end
    assert_response :success
  end

  # --- Tags ---

  test 'list tags' do
    get api_v1_tags_url, headers: auth_headers(@teacher), as: :json
    assert_response :success
    json = JSON.parse(response.body)
    assert json.is_a?(Array)
  end

  private

  def auth_headers(user)
    { 'Authorization' => "Bearer #{user.api_token}" }
  end
end
