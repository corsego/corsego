# frozen_string_literal: true

module Api
  module V1
    class TagsController < BaseController
      before_action :find_owned_course!, only: %i[add_to_course remove_from_course]

      def index
        tags = Tag.order(:name)
        render json: tags.map { |t| { id: t.id, name: t.name, courses_count: t.course_tags_count } }
      end

      def add_to_course
        tag_ids = Array(params[:tag_ids]).map(&:to_i)
        tags = Tag.where(id: tag_ids)

        tags.each do |tag|
          @course.course_tags.find_or_create_by(tag: tag)
        end

        render json: {
          message: 'Tags updated.',
          tags: @course.tags.reload.map { |t| { id: t.id, name: t.name } }
        }
      end

      def remove_from_course
        tag = Tag.find(params[:tag_id])
        @course.course_tags.where(tag: tag).destroy_all
        render json: {
          message: 'Tag removed.',
          tags: @course.tags.reload.map { |t| { id: t.id, name: t.name } }
        }
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Tag not found.' }, status: :not_found
      end
    end
  end
end
