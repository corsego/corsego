# frozen_string_literal: true

class CheckoutController < ApplicationController
  before_action :set_course
  before_action :validate_checkout

  def create
    @session = Stripe::Checkout::Session.create({
                                                  customer: current_user.stripe_customer_id,
                                                  payment_method_types: ['card'],
                                                  line_items: [{
                                                    price: @course.stripe_price_id,
                                                    quantity: 1
                                                  }],
                                                  mode: 'payment',
                                                  success_url: course_url(@course),
                                                  cancel_url: course_url(@course)
                                                })
    respond_to do |format|
      format.js
    end
  end

  private

  def set_course
    @course = Course.friendly.find(params[:id])
  end

  def validate_checkout
    if @course.user == current_user
      redirect_to course_path(@course), alert: 'You cannot purchase your own course.'
      return
    end

    if current_user.bought?(@course)
      redirect_to course_path(@course), alert: 'You are already enrolled in this course.'
      return
    end

    return if @course.published? && @course.approved?

    redirect_to course_path(@course), alert: 'This course is not available for purchase.'
  end
end
