# frozen_string_literal: true

module Api
  module V1
    class CoursesController < BaseController
      before_action :require_teacher!, only: %i[create]
      before_action :find_owned_course!, only: %i[show update destroy publish]

      def index
        courses = current_user.courses.order(created_at: :desc)
        render json: courses.map { |c| course_summary(c) }
      end

      def show
        render json: course_detail(@course)
      end

      def create
        course = current_user.courses.new(course_params)
        course.marketing_description = 'Marketing Description' if course.marketing_description.blank?
        course.description = 'Curriculum Description' if course.description.blank?

        without_tracking do
          if course.save
            render json: course_detail(course), status: :created
          else
            render json: { errors: course.errors.full_messages }, status: :unprocessable_entity
          end
        end
      end

      def update
        without_tracking do
          if @course.update(course_params)
            render json: course_detail(@course)
          else
            render json: { errors: @course.errors.full_messages }, status: :unprocessable_entity
          end
        end
      end

      def destroy
        if @course.enrollments.any?
          render json: { error: 'Cannot delete a course with existing enrollments.' }, status: :unprocessable_entity
        elsif @course.destroy
          render json: { message: 'Course deleted.' }
        else
          render json: { errors: @course.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def publish
        new_status = !@course.published
        @course.update_column(:published, new_status)
        render json: {
          message: new_status ? 'Course published.' : 'Course unpublished.',
          published: new_status
        }
      end

      private

      def course_params
        params.permit(:title, :marketing_description, :description, :price, :language, :level)
      end

      def course_summary(course)
        {
          id: course.id,
          slug: course.slug,
          title: course.title,
          marketing_description: course.marketing_description,
          price: course.price,
          language: course.language,
          level: course.level,
          published: course.published,
          approved: course.approved,
          chapters_count: course.chapters_count,
          lessons_count: course.lessons_count,
          enrollments_count: course.enrollments_count,
          average_rating: course.average_rating,
          created_at: course.created_at,
          updated_at: course.updated_at
        }
      end

      def course_detail(course)
        course_summary(course).merge(
          description: course.description.to_s,
          income: course.income,
          stripe_product_id: course.stripe_product_id,
          stripe_price_id: course.stripe_price_id,
          tags: course.tags.map { |t| { id: t.id, name: t.name } },
          chapters: course.chapters.rank(:row_order).map do |chapter|
            {
              id: chapter.id,
              slug: chapter.slug,
              title: chapter.title,
              position: chapter.row_order,
              lessons_count: chapter.lessons_count,
              lessons: chapter.lessons.rank(:row_order).map do |lesson|
                {
                  id: lesson.id,
                  slug: lesson.slug,
                  title: lesson.title,
                  content: lesson.content.to_s,
                  video_url: lesson.video_url,
                  position: lesson.row_order
                }
              end
            }
          end
        )
      end
    end
  end
end
