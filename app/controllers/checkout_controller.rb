# frozen_string_literal: true

class CheckoutController < ApplicationController
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

    enrollment = nil
    course = nil

    session.line_items.data.each do |line_item|
      course = Course.find_by(stripe_product_id: line_item.price.product)
      next unless course

      enrollment, newly_created = user.enroll_in_course(course, price: line_item.amount_total)

      if newly_created && enrollment.present?
        EnrollmentMailer.student_enrollment(enrollment).deliver_later
        EnrollmentMailer.teacher_enrollment(enrollment).deliver_later
      end
    end

    if enrollment&.persisted?
      flash[:notice] = 'Payment successful! You are now enrolled in the course.'
      redirect_to course_path(course)
    else
      flash[:alert] = 'Unable to complete enrollment. Please contact support.'
      redirect_to root_path
    end
  end
end
