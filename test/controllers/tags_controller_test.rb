# frozen_string_literal: true

require 'test_helper'

class TagsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @admin = users(:admin)
    @teacher = users(:teacher)
    @student = users(:student)
    @ruby_tag = tags(:ruby)
  end

  # INDEX
  test 'anyone can access tags index without authentication' do
    get tags_url
    assert_response :success
  end

  test 'authenticated user can access tags index' do
    sign_in @student
    get tags_url
    assert_response :success
  end

  # CREATE
  test 'admin can create tag' do
    sign_in @admin

    assert_difference 'Tag.count', 1 do
      post tags_url, params: { tag: { name: 'NewTag' } }, as: :json
    end

    assert_response :success
  end

  test 'non-admin cannot create tag' do
    sign_in @student

    assert_no_difference 'Tag.count' do
      post tags_url, params: { tag: { name: 'StudentTag' } }, as: :json
    end
  end

  test 'create tag with invalid data returns errors' do
    sign_in @admin

    assert_no_difference 'Tag.count' do
      post tags_url, params: { tag: { name: '' } }, as: :json
    end

    response_body = JSON.parse(response.body)
    assert response_body['errors'].present?
  end

  test 'unauthenticated user cannot create tag' do
    assert_no_difference 'Tag.count' do
      post tags_url, params: { tag: { name: 'NewTag' } }, as: :json
    end
  end

  # DESTROY
  test 'admin can destroy tag' do
    sign_in @admin
    tag = Tag.create!(name: 'DeleteMe')

    assert_difference 'Tag.count', -1 do
      delete tag_url(tag)
    end

    assert_redirected_to tags_path
  end

  test 'non-admin cannot destroy tag' do
    sign_in @student
    tag = Tag.create!(name: 'CannotDelete')

    assert_no_difference 'Tag.count' do
      delete tag_url(tag)
    end

    assert_redirected_to root_url
  end
end
