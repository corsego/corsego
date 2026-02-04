# frozen_string_literal: true

module Api
  module V1
    class LessonsController < BaseController
      before_action :find_owned_course!
      before_action :find_lesson!, only: %i[update destroy]

      def create
        chapter = @course.chapters.friendly.find(params[:chapter_id])
        lesson = @course.lessons.new(lesson_params.merge(chapter: chapter))

        without_tracking do
          if lesson.save
            render json: lesson_json(lesson), status: :created
          else
            render json: { errors: lesson.errors.full_messages }, status: :unprocessable_entity
          end
        end
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Chapter not found.' }, status: :not_found
      end

      def update
        without_tracking do
          if @lesson.update(lesson_params)
            render json: lesson_json(@lesson)
          else
            render json: { errors: @lesson.errors.full_messages }, status: :unprocessable_entity
          end
        end
      end

      def destroy
        @lesson.destroy!
        render json: { message: 'Lesson deleted.' }
      end

      def reorder
        ids = params[:ordered_ids]
        unless ids.is_a?(Array) && ids.all? { |id| id.is_a?(Integer) || id.to_s =~ /\A\d+\z/ }
          return render json: { error: 'Provide ordered_ids as an array of lesson IDs.' }, status: :unprocessable_entity
        end

        ids.each_with_index do |id, index|
          lesson = @course.lessons.find_by(id: id)
          lesson&.update!(row_order_position: index)
        end
        render json: { message: 'Lessons reordered.' }
      end

      private

      def find_lesson!
        @lesson = @course.lessons.friendly.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Lesson not found.' }, status: :not_found
      end

      def lesson_params
        params.permit(:title, :content, :video_url, :chapter_id, :row_order_position)
      end

      def lesson_json(lesson)
        {
          id: lesson.id,
          slug: lesson.slug,
          title: lesson.title,
          content: lesson.content.to_s,
          video_url: lesson.video_url,
          chapter_id: lesson.chapter_id,
          position: lesson.row_order
        }
      end
    end
  end
end
