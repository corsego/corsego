# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '>= 3.4.0'

gem 'rails', '~> 8.1.1'
gem 'pg', '>= 0.18', '< 2.0'
gem 'puma', '~> 6.0'
gem 'sprockets-rails'
gem 'sassc-rails' # SCSS compilation for asset pipeline
gem 'turbo-rails'
gem 'stimulus-rails'
gem 'jbuilder', '~> 2.7'
gem 'bootsnap', require: false

group :development do
  gem 'web-console'
  gem 'listen'
  gem 'rubocop-rails', require: false
  gem 'standard', require: false
  gem 'brakeman', require: false # security vulnerability scanner (Rails 8 default)
  gem 'letter_opener'
  gem 'letter_opener_web' # web interface for letter_opener
  gem 'rails-erd' # sudo apt-get install graphviz; bundle exec erd
end

group :development, :test do
  gem 'debug', platforms: %i[mri windows]
  gem 'dotenv-rails' # load environment variables from .env
  gem 'faker' # fake data for seeds.rb
  gem 'mocha' # mocking and stubbing for tests
  gem 'minitest' # Testing framework
  gem 'webmock' # stub HTTP requests in tests
end

group :test do
  gem 'capybara' # system testing
  gem 'selenium-webdriver' # browser driver for system tests
end

# Frontend
gem 'haml-rails', '~> 2.0' # HTML abstraction markup language
gem 'simple_form' # creating forms made easier
gem 'cocoon' # nested forms

# Authentication
gem 'devise'
gem 'devise_invitable', '~> 2.0' # invite users
gem 'omniauth-google-oauth2' # sign in with google
gem 'omniauth-github' # sign in with github
gem 'omniauth-facebook' # sign in with facebook
gem 'omniauth-rails_csrf_protection'

# Active Record
gem 'friendly_id', '~> 5.5' # nice URLs and hide IDs
gem 'ransack', '~> 4.4' # Rails 8.1 compatible
gem 'public_activity' # see all activity in the app
gem 'rolify' # give users roles (admin, teacher, student)
gem 'pundit' # authorization (different roles have different accesses)
gem 'pagy', '~> 8.0' # v9+ changed Backend/Frontend module API
gem 'ranked-model' # give serial/index numbers to items in a list
gem 'wicked' # multistep forms
gem 'sitemap_generator' # SEO and webmasters

gem 'chartkick' # charts #yarn add chartkick chart.js
gem 'groupdate' # group records by day/week/year

# Storage
gem 'aws-sdk-s3', require: false # save images and files in production
gem 'active_storage_validations' # validate image and file uploads
gem 'image_processing' # sudo apt install imagemagick

# PDF
gem 'prawn' # Pure Ruby PDF generation
gem 'prawn-table' # Table support for Prawn
gem 'rqrcode' # QR code generation for certificates

gem 'stripe' # accept payments

gem 'invisible_captcha' # honeypot spam protection for registration

# Error monitoring and uptime
gem 'honeybadger'

# Background jobs
gem 'good_job', '~> 4.0'
