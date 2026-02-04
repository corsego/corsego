# frozen_string_literal: true

module Api
  module V1
    class ChaptersController < BaseController
      before_action :find_owned_course!
      before_action :find_chapter!, only: %i[update destroy]

      def create
        chapter = @course.chapters.new(chapter_params)
        if chapter.save
          render json: chapter_json(chapter), status: :created
        else
          render json: { errors: chapter.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        if @chapter.update(chapter_params)
          render json: chapter_json(@chapter)
        else
          render json: { errors: @chapter.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        @chapter.destroy!
        render json: { message: 'Chapter deleted.' }
      end

      def reorder
        ids = params[:ordered_ids]
        unless ids.is_a?(Array) && ids.all? { |id| id.is_a?(Integer) || id.to_s =~ /\A\d+\z/ }
          return render json: { error: 'Provide ordered_ids as an array of chapter IDs.' }, status: :unprocessable_entity
        end

        ids.each_with_index do |id, index|
          chapter = @course.chapters.find_by(id: id)
          chapter&.update!(row_order_position: index)
        end
        render json: { message: 'Chapters reordered.', chapters: @course.chapters.rank(:row_order).map { |c| chapter_json(c) } }
      end

      private

      def find_chapter!
        @chapter = @course.chapters.friendly.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Chapter not found.' }, status: :not_found
      end

      def chapter_params
        params.permit(:title, :row_order_position)
      end

      def chapter_json(chapter)
        {
          id: chapter.id,
          slug: chapter.slug,
          title: chapter.title,
          position: chapter.row_order,
          lessons_count: chapter.lessons_count
        }
      end
    end
  end
end
