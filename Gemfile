# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '2.7.3'

gem 'rails', '~> 6.1.3.2'
# gem 'rails', github: 'rails/rails', branch: 'master'
gem 'pg', '>= 0.18', '< 2.0'
gem 'puma', '~> 4.1'
gem 'sass-rails', '>= 6'
gem 'webpacker', '~> 4.0'
gem 'turbolinks', '~> 5'
gem 'jbuilder', '~> 2.7'
gem 'bootsnap', '>= 1.4.2', require: false

group :development do
  gem 'byebug', platforms: %i[mri mingw x64_mingw]
  gem 'web-console', '>= 3.3.0'
  gem 'listen', '>= 3.0.5', '< 3.2'
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
  gem 'rubocop-rails', require: false
  gem 'standard'
  gem 'letter_opener'  
  gem 'rails-erd' # sudo apt-get install graphviz; bundle exec erd
end

group :development, :test do
  gem 'faker' # fake data for seeds.rb
end

# Frontend
gem 'haml-rails', '~> 2.0' # HTML abstraction markup language
# gem 'font-awesome-sass', '~> 5.12.0' #add icons for styling #installed via yarn withot gem
gem 'simple_form' # creating forms made easier
gem 'cocoon' # nested forms

# Authentication
gem 'devise', github: 'heartcombo/devise', branch: 'master' # https://stackoverflow.com/a/66155946/5695646
gem 'devise_invitable', '~> 2.0.0' # invite users
gem 'omniauth-google-oauth2' # sign in with google
gem 'omniauth-github' # sign in with github
gem 'omniauth-facebook' # sign in with facebook
gem 'omniauth-rails_csrf_protection'

# Active Record
gem 'friendly_id', '~> 5.2.4' # nice URLs and hide IDs
gem 'ransack' # filter and sort data
gem 'public_activity' # see all activity in the app
gem 'rolify' # give users roles (admin, teacher, student)
gem 'pundit' # authorization (different roles have different accesses)
gem 'pagy' # pagination
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
gem 'wicked_pdf' # PDF for Ruby on Rails
gem 'wkhtmltopdf-binary', group: :development
gem 'wkhtmltopdf-heroku', group: :production

gem 'stripe' # accept payments

# TODO: replace with invisible_captcha
gem 'recaptcha' # for new user registration
