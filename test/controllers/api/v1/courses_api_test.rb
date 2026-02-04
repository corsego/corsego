# frozen_string_literal: true

require 'test_helper'

class Api::V1::CoursesApiTest < ActionDispatch::IntegrationTest
  setup do
    @teacher = users(:teacher)
    @another_teacher = users(:another_teacher)
    @student = users(:student)
    @admin = users(:admin)
    @published_course = courses(:published_course)
    @unpublished_course = courses(:unpublished_course)
    @free_course = courses(:free_course)
    @chapter = chapters(:chapter_one)
    @chapter_advanced = chapters(:chapter_advanced)
    @lesson = lessons(:lesson_one)
    @lesson_two = lessons(:lesson_two)
    @tag_ruby = tags(:ruby)
    @tag_rails = tags(:rails)
    @tag_programming = tags(:programming)

    # ActionText rich text fields are not populated by YAML fixtures.
    # Create the ActionText records so validations pass on update.
    @unpublished_course.description = 'Advanced Ruby programming techniques'
    @unpublished_course.marketing_description = 'Take your Ruby skills to the next level'
    @unpublished_course.save!(validate: false)

    @published_course.description = 'Learn Ruby programming fundamentals'
    @published_course.marketing_description = 'Master Ruby programming from scratch'
    @published_course.save!(validate: false)

    @lesson.content = 'Learn about variables in Ruby'
    @lesson.save!(validate: false)

    @lesson_two.content = 'Learn about strings in Ruby'
    @lesson_two.save!(validate: false)
  end

  # ===================================================================
  # Authentication
  # ===================================================================

  test 'auth: valid credentials return token, email, name, and roles' do
    post api_v1_auth_token_url, params: { email: @teacher.email, password: 'password' }, as: :json
    assert_response :success
    json = JSON.parse(response.body)
    assert json['api_token'].present?
    assert_equal @teacher.email, json['email']
    assert json.key?('name')
    assert json['roles'].is_a?(Array)
  end

  test 'auth: invalid password returns unauthorized' do
    post api_v1_auth_token_url, params: { email: @teacher.email, password: 'wrong' }, as: :json
    assert_response :unauthorized
    json = JSON.parse(response.body)
    assert_equal 'Invalid email or password.', json['error']
  end

  test 'auth: non-existent email returns unauthorized' do
    post api_v1_auth_token_url, params: { email: 'nobody@example.com', password: 'password' }, as: :json
    assert_response :unauthorized
  end

  test 'auth: blank email and password returns unauthorized' do
    post api_v1_auth_token_url, params: { email: '', password: '' }, as: :json
    assert_response :unauthorized
  end

  test 'auth: request without token returns unauthorized' do
    get api_v1_courses_url, as: :json
    assert_response :unauthorized
    json = JSON.parse(response.body)
    assert json['error'].include?('Unauthorized')
  end

  test 'auth: invalid token returns unauthorized' do
    get api_v1_courses_url, headers: { 'Authorization' => 'Bearer invalid_token_xyz' }, as: :json
    assert_response :unauthorized
  end

  test 'auth: empty bearer token returns unauthorized' do
    get api_v1_courses_url, headers: { 'Authorization' => 'Bearer ' }, as: :json
    assert_response :unauthorized
  end

  test 'auth: malformed authorization header returns unauthorized' do
    get api_v1_courses_url, headers: { 'Authorization' => 'Token abc123' }, as: :json
    assert_response :unauthorized
  end

  # ===================================================================
  # Courses - Index
  # ===================================================================

  test 'courses#index: returns only courses owned by authenticated user' do
    get api_v1_courses_url, headers: auth_headers(@teacher), as: :json
    assert_response :success
    json = JSON.parse(response.body)
    assert json.is_a?(Array)
    # Teacher owns published_course and unpublished_course
    titles = json.map { |c| c['title'] }
    assert_includes titles, @published_course.title
    assert_includes titles, @unpublished_course.title
    # Does not include free_course (owned by another_teacher)
    assert_not_includes titles, @free_course.title
  end

  test 'courses#index: returns empty array for user with no courses' do
    get api_v1_courses_url, headers: auth_headers(@student), as: :json
    assert_response :success
    json = JSON.parse(response.body)
    assert_equal [], json
  end

  test 'courses#index: includes expected summary fields' do
    get api_v1_courses_url, headers: auth_headers(@teacher), as: :json
    json = JSON.parse(response.body)
    course = json.find { |c| c['title'] == @published_course.title }
    %w[id slug title price language level published approved
       chapters_count lessons_count enrollments_count average_rating].each do |field|
      assert course.key?(field), "Missing field: #{field}"
    end
  end

  # ===================================================================
  # Courses - Show
  # ===================================================================

  test 'courses#show: returns full details with chapters and lessons' do
    get api_v1_course_url(@published_course), headers: auth_headers(@teacher), as: :json
    assert_response :success
    json = JSON.parse(response.body)
    assert_equal @published_course.title, json['title']
    assert json['chapters'].is_a?(Array)
    assert json['tags'].is_a?(Array)
    assert json.key?('description')
    assert json.key?('income')
    # Verify nested structure
    chapter = json['chapters'].first
    assert chapter.key?('lessons') if chapter
  end

  test 'courses#show: non-owner cannot view course' do
    get api_v1_course_url(@published_course), headers: auth_headers(@student), as: :json
    assert_response :not_found
  end

  test 'courses#show: non-existent course returns not found' do
    get api_v1_course_url(id: 'nonexistent-slug'), headers: auth_headers(@teacher), as: :json
    assert_response :not_found
    json = JSON.parse(response.body)
    assert json['error'].present?
  end

  # ===================================================================
  # Courses - Create
  # ===================================================================

  test 'courses#create: teacher creates course with valid params' do
    assert_difference 'Course.count', 1 do
      post api_v1_courses_url, headers: auth_headers(@teacher), as: :json,
           params: { title: 'MCP Test Course', price: 2900, language: 'English', level: 'Beginner' }
    end
    assert_response :created
    json = JSON.parse(response.body)
    assert_equal 'MCP Test Course', json['title']
    assert_equal 2900, json['price']
    assert_equal 'English', json['language']
    assert_equal 'Beginner', json['level']
  end

  test 'courses#create: sets default descriptions when not provided' do
    post api_v1_courses_url, headers: auth_headers(@teacher), as: :json,
         params: { title: 'Defaults Test Course' }
    assert_response :created
    json = JSON.parse(response.body)
    assert_equal 'Marketing Description', json['marketing_description']
  end

  test 'courses#create: non-teacher cannot create course' do
    assert_no_difference 'Course.count' do
      post api_v1_courses_url, headers: auth_headers(@student), as: :json,
           params: { title: 'Student Course Attempt' }
    end
    assert_response :forbidden
    json = JSON.parse(response.body)
    assert json['error'].include?('teacher')
  end

  test 'courses#create: rejects duplicate title' do
    assert_no_difference 'Course.count' do
      post api_v1_courses_url, headers: auth_headers(@teacher), as: :json,
           params: { title: @published_course.title }
    end
    assert_response :unprocessable_entity
    json = JSON.parse(response.body)
    assert json['errors'].is_a?(Array)
  end

  test 'courses#create: rejects blank title' do
    assert_no_difference 'Course.count' do
      post api_v1_courses_url, headers: auth_headers(@teacher), as: :json,
           params: { title: '' }
    end
    assert_response :unprocessable_entity
  end

  # ===================================================================
  # Courses - Update
  # ===================================================================

  test 'courses#update: owner updates course fields' do
    patch api_v1_course_url(@unpublished_course), headers: auth_headers(@teacher), as: :json,
          params: { marketing_description: 'Updated via API', price: 5900 }
    assert_response :success
    json = JSON.parse(response.body)
    assert_equal 'Updated via API', json['marketing_description']
    assert_equal 5900, json['price']
  end

  test 'courses#update: non-owner cannot update course' do
    patch api_v1_course_url(@published_course), headers: auth_headers(@student), as: :json,
          params: { title: 'Hacked' }
    assert_response :not_found
    @published_course.reload
    assert_not_equal 'Hacked', @published_course.title
  end

  test 'courses#update: non-existent course returns not found' do
    patch api_v1_course_url(id: 'nonexistent'), headers: auth_headers(@teacher), as: :json,
          params: { title: 'Whatever' }
    assert_response :not_found
  end

  test 'courses#update: returns validation errors for invalid data' do
    patch api_v1_course_url(@unpublished_course), headers: auth_headers(@teacher), as: :json,
          params: { title: '' }
    assert_response :unprocessable_entity
    json = JSON.parse(response.body)
    assert json['errors'].is_a?(Array)
    assert json['errors'].any? { |e| e.downcase.include?('title') }
  end

  # ===================================================================
  # Courses - Publish
  # ===================================================================

  test 'courses#publish: toggles from unpublished to published' do
    assert_not @unpublished_course.published
    patch publish_api_v1_course_url(@unpublished_course), headers: auth_headers(@teacher), as: :json
    assert_response :success
    json = JSON.parse(response.body)
    assert json['published']
    assert_equal 'Course published.', json['message']
  end

  test 'courses#publish: toggles from published to unpublished' do
    assert @published_course.published
    patch publish_api_v1_course_url(@published_course), headers: auth_headers(@teacher), as: :json
    assert_response :success
    json = JSON.parse(response.body)
    assert_not json['published']
    assert_equal 'Course unpublished.', json['message']
  end

  test 'courses#publish: non-owner cannot publish' do
    patch publish_api_v1_course_url(@published_course), headers: auth_headers(@student), as: :json
    assert_response :not_found
  end

  # ===================================================================
  # Courses - Destroy
  # ===================================================================

  test 'courses#destroy: owner deletes course without enrollments' do
    assert_difference 'Course.count', -1 do
      delete api_v1_course_url(@unpublished_course), headers: auth_headers(@teacher), as: :json
    end
    assert_response :success
    json = JSON.parse(response.body)
    assert_equal 'Course deleted.', json['message']
  end

  test 'courses#destroy: cannot delete course with enrollments' do
    assert_no_difference 'Course.count' do
      delete api_v1_course_url(@published_course), headers: auth_headers(@teacher), as: :json
    end
    assert_response :unprocessable_entity
    json = JSON.parse(response.body)
    assert json['error'].include?('enrollments')
  end

  test 'courses#destroy: non-owner cannot delete course' do
    assert_no_difference 'Course.count' do
      delete api_v1_course_url(@unpublished_course), headers: auth_headers(@student), as: :json
    end
    assert_response :not_found
  end

  test 'courses#destroy: non-existent course returns not found' do
    delete api_v1_course_url(id: 'nonexistent'), headers: auth_headers(@teacher), as: :json
    assert_response :not_found
  end

  # ===================================================================
  # Chapters - Create
  # ===================================================================

  test 'chapters#create: creates chapter with valid title' do
    assert_difference 'Chapter.count', 1 do
      post api_v1_course_chapters_url(@published_course), headers: auth_headers(@teacher), as: :json,
           params: { title: 'New Chapter via API' }
    end
    assert_response :created
    json = JSON.parse(response.body)
    assert_equal 'New Chapter via API', json['title']
    assert json.key?('id')
    assert json.key?('slug')
    assert json.key?('position')
  end

  test 'chapters#create: rejects blank title' do
    assert_no_difference 'Chapter.count' do
      post api_v1_course_chapters_url(@published_course), headers: auth_headers(@teacher), as: :json,
           params: { title: '' }
    end
    assert_response :unprocessable_entity
  end

  test 'chapters#create: non-owner cannot create chapter' do
    assert_no_difference 'Chapter.count' do
      post api_v1_course_chapters_url(@published_course), headers: auth_headers(@student), as: :json,
           params: { title: 'Unauthorized Chapter' }
    end
    assert_response :not_found
  end

  # ===================================================================
  # Chapters - Update
  # ===================================================================

  test 'chapters#update: updates chapter title' do
    patch api_v1_course_chapter_url(@published_course, @chapter), headers: auth_headers(@teacher), as: :json,
          params: { title: 'Updated Chapter Title' }
    assert_response :success
    json = JSON.parse(response.body)
    assert_equal 'Updated Chapter Title', json['title']
  end

  test 'chapters#update: non-owner cannot update chapter' do
    patch api_v1_course_chapter_url(@published_course, @chapter), headers: auth_headers(@student), as: :json,
          params: { title: 'Hacked Chapter' }
    assert_response :not_found
  end

  test 'chapters#update: non-existent chapter returns not found' do
    patch api_v1_course_chapter_url(@published_course, id: 999_999), headers: auth_headers(@teacher), as: :json,
          params: { title: 'Ghost Chapter' }
    assert_response :not_found
  end

  test 'chapters#update: rejects invalid data' do
    patch api_v1_course_chapter_url(@published_course, @chapter), headers: auth_headers(@teacher), as: :json,
          params: { title: '' }
    assert_response :unprocessable_entity
  end

  # ===================================================================
  # Chapters - Destroy
  # ===================================================================

  test 'chapters#destroy: deletes chapter' do
    assert_difference 'Chapter.count', -1 do
      delete api_v1_course_chapter_url(@unpublished_course, @chapter_advanced), headers: auth_headers(@teacher), as: :json
    end
    assert_response :success
    json = JSON.parse(response.body)
    assert_equal 'Chapter deleted.', json['message']
  end

  test 'chapters#destroy: non-owner cannot delete chapter' do
    assert_no_difference 'Chapter.count' do
      delete api_v1_course_chapter_url(@published_course, @chapter), headers: auth_headers(@student), as: :json
    end
    assert_response :not_found
  end

  test 'chapters#destroy: non-existent chapter returns not found' do
    delete api_v1_course_chapter_url(@published_course, id: 999_999), headers: auth_headers(@teacher), as: :json
    assert_response :not_found
  end

  # ===================================================================
  # Chapters - Reorder
  # ===================================================================

  test 'chapters#reorder: reorders chapters by given IDs' do
    # Create a second chapter so we can reorder
    post api_v1_course_chapters_url(@published_course), headers: auth_headers(@teacher), as: :json,
         params: { title: 'Second Chapter' }
    second_chapter_id = JSON.parse(response.body)['id']

    patch reorder_api_v1_course_chapters_url(@published_course), headers: auth_headers(@teacher), as: :json,
          params: { ordered_ids: [second_chapter_id, @chapter.id] }
    assert_response :success
    json = JSON.parse(response.body)
    assert_equal 'Chapters reordered.', json['message']
    assert json['chapters'].is_a?(Array)
  end

  test 'chapters#reorder: rejects non-array ordered_ids' do
    patch reorder_api_v1_course_chapters_url(@published_course), headers: auth_headers(@teacher), as: :json,
          params: { ordered_ids: 'not_an_array' }
    assert_response :unprocessable_entity
  end

  test 'chapters#reorder: rejects missing ordered_ids' do
    patch reorder_api_v1_course_chapters_url(@published_course), headers: auth_headers(@teacher), as: :json,
          params: {}
    assert_response :unprocessable_entity
  end

  test 'chapters#reorder: non-owner cannot reorder' do
    patch reorder_api_v1_course_chapters_url(@published_course), headers: auth_headers(@student), as: :json,
          params: { ordered_ids: [@chapter.id] }
    assert_response :not_found
  end

  # ===================================================================
  # Lessons - Create
  # ===================================================================

  test 'lessons#create: creates lesson with valid params' do
    assert_difference 'Lesson.count', 1 do
      post api_v1_course_lessons_url(@published_course), headers: auth_headers(@teacher), as: :json,
           params: { title: 'New Lesson via API', content: 'Lesson content here', chapter_id: @chapter.id }
    end
    assert_response :created
    json = JSON.parse(response.body)
    assert_equal 'New Lesson via API', json['title']
    assert_equal @chapter.id, json['chapter_id']
  end

  test 'lessons#create: creates lesson with video_url' do
    post api_v1_course_lessons_url(@published_course), headers: auth_headers(@teacher), as: :json,
         params: { title: 'Video Lesson', content: 'Content', chapter_id: @chapter.id,
                   video_url: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ' }
    assert_response :created
    json = JSON.parse(response.body)
    assert_equal 'https://www.youtube.com/watch?v=dQw4w9WgXcQ', json['video_url']
  end

  test 'lessons#create: non-existent chapter returns not found' do
    assert_no_difference 'Lesson.count' do
      post api_v1_course_lessons_url(@published_course), headers: auth_headers(@teacher), as: :json,
           params: { title: 'Orphan Lesson', content: 'Content', chapter_id: 999_999 }
    end
    assert_response :not_found
    json = JSON.parse(response.body)
    assert_equal 'Chapter not found.', json['error']
  end

  test 'lessons#create: non-owner cannot create lesson' do
    assert_no_difference 'Lesson.count' do
      post api_v1_course_lessons_url(@published_course), headers: auth_headers(@student), as: :json,
           params: { title: 'Unauthorized Lesson', content: 'Content', chapter_id: @chapter.id }
    end
    assert_response :not_found
  end

  test 'lessons#create: rejects blank title' do
    assert_no_difference 'Lesson.count' do
      post api_v1_course_lessons_url(@published_course), headers: auth_headers(@teacher), as: :json,
           params: { title: '', content: 'Content', chapter_id: @chapter.id }
    end
    assert_response :unprocessable_entity
  end

  # ===================================================================
  # Lessons - Update
  # ===================================================================

  test 'lessons#update: updates lesson title and content' do
    patch api_v1_course_lesson_url(@published_course, @lesson), headers: auth_headers(@teacher), as: :json,
          params: { title: 'Updated Lesson Title', content: 'Updated content' }
    assert_response :success
    json = JSON.parse(response.body)
    assert_equal 'Updated Lesson Title', json['title']
  end

  test 'lessons#update: non-owner cannot update lesson' do
    patch api_v1_course_lesson_url(@published_course, @lesson), headers: auth_headers(@student), as: :json,
          params: { title: 'Hacked Lesson' }
    assert_response :not_found
  end

  test 'lessons#update: non-existent lesson returns not found' do
    patch api_v1_course_lesson_url(@published_course, id: 999_999), headers: auth_headers(@teacher), as: :json,
          params: { title: 'Ghost Lesson' }
    assert_response :not_found
  end

  # ===================================================================
  # Lessons - Destroy
  # ===================================================================

  test 'lessons#destroy: deletes lesson' do
    lesson = lessons(:lesson_advanced)
    assert_difference 'Lesson.count', -1 do
      delete api_v1_course_lesson_url(@unpublished_course, lesson), headers: auth_headers(@teacher), as: :json
    end
    assert_response :success
    json = JSON.parse(response.body)
    assert_equal 'Lesson deleted.', json['message']
  end

  test 'lessons#destroy: non-owner cannot delete lesson' do
    assert_no_difference 'Lesson.count' do
      delete api_v1_course_lesson_url(@published_course, @lesson), headers: auth_headers(@student), as: :json
    end
    assert_response :not_found
  end

  test 'lessons#destroy: non-existent lesson returns not found' do
    delete api_v1_course_lesson_url(@published_course, id: 999_999), headers: auth_headers(@teacher), as: :json
    assert_response :not_found
  end

  # ===================================================================
  # Lessons - Reorder
  # ===================================================================

  test 'lessons#reorder: reorders lessons by given IDs' do
    patch reorder_api_v1_course_lessons_url(@published_course), headers: auth_headers(@teacher), as: :json,
          params: { ordered_ids: [@lesson_two.id, @lesson.id] }
    assert_response :success
    json = JSON.parse(response.body)
    assert_equal 'Lessons reordered.', json['message']
  end

  test 'lessons#reorder: rejects non-array ordered_ids' do
    patch reorder_api_v1_course_lessons_url(@published_course), headers: auth_headers(@teacher), as: :json,
          params: { ordered_ids: 'not_an_array' }
    assert_response :unprocessable_entity
  end

  test 'lessons#reorder: rejects missing ordered_ids' do
    patch reorder_api_v1_course_lessons_url(@published_course), headers: auth_headers(@teacher), as: :json,
          params: {}
    assert_response :unprocessable_entity
  end

  test 'lessons#reorder: non-owner cannot reorder' do
    patch reorder_api_v1_course_lessons_url(@published_course), headers: auth_headers(@student), as: :json,
          params: { ordered_ids: [@lesson.id, @lesson_two.id] }
    assert_response :not_found
  end

  # ===================================================================
  # Tags - Index
  # ===================================================================

  test 'tags#index: returns all tags with expected fields' do
    get api_v1_tags_url, headers: auth_headers(@teacher), as: :json
    assert_response :success
    json = JSON.parse(response.body)
    assert json.is_a?(Array)
    assert json.length >= 3 # ruby, rails, programming from fixtures
    tag = json.first
    %w[id name courses_count].each do |field|
      assert tag.key?(field), "Missing field: #{field}"
    end
  end

  # ===================================================================
  # Tags - Add to Course
  # ===================================================================

  test 'tags#add_to_course: adds tags to course' do
    post api_v1_course_tags_url(@unpublished_course), headers: auth_headers(@teacher), as: :json,
         params: { tag_ids: [@tag_ruby.id, @tag_programming.id] }
    assert_response :success
    json = JSON.parse(response.body)
    assert_equal 'Tags updated.', json['message']
    tag_names = json['tags'].map { |t| t['name'] }
    assert_includes tag_names, 'Ruby'
    assert_includes tag_names, 'Programming'
  end

  test 'tags#add_to_course: adding duplicate tag does not create duplicate' do
    # published_course already has the ruby tag via course_tags fixture
    assert_no_difference 'CourseTag.count' do
      post api_v1_course_tags_url(@published_course), headers: auth_headers(@teacher), as: :json,
           params: { tag_ids: [@tag_ruby.id] }
    end
    assert_response :success
  end

  test 'tags#add_to_course: non-owner cannot add tags' do
    post api_v1_course_tags_url(@published_course), headers: auth_headers(@student), as: :json,
         params: { tag_ids: [@tag_programming.id] }
    assert_response :not_found
  end

  test 'tags#add_to_course: non-existent course returns not found' do
    post api_v1_course_tags_url(course_id: 'nonexistent'), headers: auth_headers(@teacher), as: :json,
         params: { tag_ids: [@tag_ruby.id] }
    assert_response :not_found
  end

  # ===================================================================
  # Tags - Remove from Course
  # ===================================================================

  test 'tags#remove_from_course: removes tag from course' do
    # published_course has ruby tag
    delete api_v1_course_remove_tag_url(@published_course, tag_id: @tag_ruby.id),
           headers: auth_headers(@teacher), as: :json
    assert_response :success
    json = JSON.parse(response.body)
    assert_equal 'Tag removed.', json['message']
    tag_ids = json['tags'].map { |t| t['id'] }
    assert_not_includes tag_ids, @tag_ruby.id
  end

  test 'tags#remove_from_course: removing non-existent tag returns not found' do
    delete api_v1_course_remove_tag_url(@published_course, tag_id: 999_999),
           headers: auth_headers(@teacher), as: :json
    assert_response :not_found
  end

  test 'tags#remove_from_course: non-owner cannot remove tags' do
    delete api_v1_course_remove_tag_url(@published_course, tag_id: @tag_ruby.id),
           headers: auth_headers(@student), as: :json
    assert_response :not_found
  end

  private

  def auth_headers(user)
    { 'Authorization' => "Bearer #{user.api_token}" }
  end
end
