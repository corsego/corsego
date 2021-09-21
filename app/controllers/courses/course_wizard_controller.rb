# frozen_string_literal: true

module Courses
  class CourseWizardController < ApplicationController
    include Wicked::Wizard
    before_action :set_progress, only: %i[show update]
    before_action :set_course, only: %i[show update finish_wizard_path]

    steps :about, :targeting, :pricing, :chapters, :publish

    def show
      authorize @course, :edit?
      case step
      when :about
      when :targeting
        @tags = Tag.all
      when :pricing
      when :chapters
        @course.chapters.build unless @course.chapters.any?
      when :publish
      end
      render_wizard
    end

    def update
      authorize @course, :edit?
      case step
      when :about
      when :targeting
        @tags = Tag.all
      when :pricing
      when :chapters
        # unless @course.chapters.any? # chapter title and content validation fires only if this line is present
        #  @course.chapters.build
        # end
      when :publish
      end
      @course.update(course_params)
      render_wizard @course
    end

    def finish_wizard_path
      authorize @course, :edit?
      # courses_path
      course_path(@course)
    end

    private

    def set_progress
      @progress = if wizard_steps.any? && wizard_steps.index(step).present?
                    ((wizard_steps.index(step) + 1).to_d / wizard_steps.count.to_d) * 100
                  else
                    0
                  end
    end

    def set_course
      @course = Course.friendly.find params[:course_id]
    end

    def course_params
      params.require(:course).permit(
        :title, :avatar, :marketing_description, :description,
        :language, :level,
        :price,
        :published,
        tag_ids: [],
        chapters_attributes: %i[id title _destroy]
      )
    end
  end
end
