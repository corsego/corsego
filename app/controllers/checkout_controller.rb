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
                                                  # line_items: [
                                                  #  price_data: {
                                                  #    product: course.stripe_product_id,
                                                  #    unit_amount: course.price.to_i * 100,
                                                  #    currency: 'usd',
                                                  #  },
                                                  #  quantity: 1,
                                                  # ],
                                                  mode: 'payment',
                                                  success_url: course_url(course),
                                                  cancel_url: course_url(course)
                                                })
    respond_to do |format|
      format.js
    end
  end
end
