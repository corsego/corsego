Rails.configuration.stripe = {
  publishable_key: (Rails.application.credentials[Rails.env.to_sym][:stripe][:publishable]).to_s,
  secret_key: (Rails.application.credentials[Rails.env.to_sym][:stripe][:secret]).to_s
}
Stripe.api_key = (Rails.application.credentials[Rails.env.to_sym][:stripe][:secret]).to_s
