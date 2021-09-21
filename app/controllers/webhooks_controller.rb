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
    rescue JSON::ParserError => e
      status 400
      return
    rescue Stripe::SignatureVerificationError => e
      puts 'Signature error'
      p e
      return
    end

    case event.type
    when 'customer.created'
      customer = event.data.object
      user = User.find_by(email: customer.email)
      user.update(stripe_customer_id: customer.id)
    when 'checkout.session.completed'
      session = event.data.object
      session_with_expand = Stripe::Checkout::Session.retrieve({ id: session.id, expand: ['line_items'] })
      user = User.find_by(stripe_customer_id: session.customer)
      session_with_expand.line_items.data.each do |line_item|
        course = Course.find_by(stripe_product_id: line_item.price.product)
        user.buy_course(course)
      end
      EnrollmentMailer.student_enrollment(@enrollment).deliver_later
      EnrollmentMailer.teacher_enrollment(@enrollment).deliver_later
    end
    render json: { message: 'success' }
  end
end
