# frozen_string_literal: true

class CheckoutController < ApplicationController
  # Rate limit checkout creation: 10 attempts per 5 minutes per user
  # Protects against abuse of Stripe API
  rate_limit to: 10, within: 5.minutes, only: :create, by: -> { current_user.id }

  def create
    course = Course.find(params[:id])
    @session = Stripe::Checkout::Session.create({
                                                  customer: current_user.stripe_customer_id,
                                                  payment_method_types: ['card'],
                                                  line_items: [{
                                                    price: course.stripe_price_id,
                                                    quantity: 1
                                                  }],
                                                  mode: 'payment',
                                                  success_url: checkout_success_url(session_id: '{CHECKOUT_SESSION_ID}'),
                                                  cancel_url: course_url(course)
                                                })
    respond_to do |format|
      format.js
    end
  end

  def success
    session_id = params[:session_id]

    if session_id.blank?
      flash[:alert] = 'Invalid checkout session.'
      redirect_to root_path and return
    end

    begin
      session = Stripe::Checkout::Session.retrieve({
                                                     id: session_id,
                                                     expand: ['line_items']
                                                   })
    rescue Stripe::InvalidRequestError => e
      Rails.logger.error "Stripe session retrieval failed: #{e.message}"
      flash[:alert] = 'Unable to verify payment. Please contact support if you were charged.'
      redirect_to root_path and return
    end

    unless session.payment_status == 'paid'
      flash[:alert] = 'Payment was not completed.'
      redirect_to root_path and return
    end

    user = User.find_by(stripe_customer_id: session.customer)
    unless user == current_user
      flash[:alert] = 'Session does not match current user.'
      redirect_to root_path and return
    end

    enrollment = Enrollment.create_from_stripe_session(session, user: user)

    if enrollment&.persisted?
      flash[:notice] = 'Payment successful! You are now enrolled in the course.'
      redirect_to course_path(enrollment.course)
    else
      flash[:alert] = 'Unable to complete enrollment. Please contact support.'
      redirect_to root_path
    end
  end
end
