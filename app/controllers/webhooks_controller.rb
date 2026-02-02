# frozen_string_literal: true

class WebhooksController < ApplicationController
  skip_before_action :authenticate_user!
  skip_before_action :verify_authenticity_token

  def create
    payload = request.body.read
    sig_header = request.env['HTTP_STRIPE_SIGNATURE']
    event = nil

    begin
      event = Stripe::Webhook.construct_event(
        payload, sig_header, Rails.application.credentials.dig(Rails.env.to_sym, :stripe, :webhook)
      )
    rescue JSON::ParserError
      head :bad_request
      return
    rescue Stripe::SignatureVerificationError => e
      Rails.logger.error "Stripe webhook signature verification failed: #{e.message}"
      head :bad_request
      return
    end

    case event.type
    when 'customer.created'
      handle_customer_created(event.data.object)
    when 'checkout.session.completed'
      handle_checkout_completed(event.data.object)
    end

    render json: { message: 'success' }
  end

  private

  def handle_customer_created(customer)
    user = User.find_by(email: customer.email)
    user&.update(stripe_customer_id: customer.id)
  end

  def handle_checkout_completed(session)
    session_with_expand = Stripe::Checkout::Session.retrieve({ id: session.id, expand: ['line_items'] })
    user = User.find_by(stripe_customer_id: session.customer)

    return unless user

    session_with_expand.line_items.data.each do |line_item|
      course = Course.find_by(stripe_product_id: line_item.price.product)
      next unless course

      # Use idempotent enrollment - webhook serves as fallback if success URL verification failed
      enrollment, newly_created = user.enroll_in_course(course, price: line_item.amount_total)

      # Only send emails if enrollment was newly created by webhook (not already created by success URL)
      if newly_created && enrollment.present?
        EnrollmentMailer.student_enrollment(enrollment).deliver_later
        EnrollmentMailer.teacher_enrollment(enrollment).deliver_later
      end
    end
  end
end
