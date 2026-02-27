# frozen_string_literal: true

class TagsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:index]

  def index
    @tags = Tag.all.where.not(course_tags_count: 0).order(course_tags_count: :desc)
  end

  def create
    @tag = Tag.new(tag_params)
    authorize @tag
    if @tag.save
      render json: @tag
    else
      render json: { errors: @tag.errors.full_messages }
    end
  end

  def destroy
    @tag = Tag.find(params[:id])
    authorize @tag
    @tag.destroy
    redirect_to tags_path, notice: 'Tag was successfully destroyed'
  end

  private

  def tag_params
    params.expect(tag: [:name])
  end
end
