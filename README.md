# Corsego - Online Learning Platform

A Udemy-like online learning platform built with Ruby on Rails. Set up your online school in minutes!

[![Demo](https://i.imgur.com/Hvjl2YJ.png)](https://corsego.herokuapp.com)

## Entity-Relationship Diagram

[![ERD](https://i.imgur.com/IIWWYxW.png)](https://corsego.herokuapp.com)

## Tech Stack

- Ruby 3.3.6
- Rails 7.1.6
- PostgreSQL
- Bun 1.3.6 (JavaScript bundler and package manager)
- Bootstrap 4.5

## Prerequisites

- Ruby 3.3.6
- Bun (v1.3+ recommended)
- PostgreSQL
- ImageMagick (for image processing)
- Graphviz (optional, for generating ERD diagrams)

### macOS

```bash
brew install postgresql imagemagick graphviz
curl -fsSL https://bun.sh/install | bash
```

### Ubuntu/Debian

```bash
sudo apt-get install postgresql libpq-dev imagemagick graphviz
curl -fsSL https://bun.sh/install | bash
```

## Installation

### 1. Clone the repository

```bash
git clone https://github.com/rormvp/corsego
cd corsego
```

### 2. Install dependencies

```bash
bundle install
bun install
```

### 3. Configure credentials

Delete the existing encrypted credentials and create your own:

```bash
rm config/credentials.yml.enc
EDITOR=vim rails credentials:edit
```

Add the following structure (replace with your actual keys):

```yaml
awss3:
  access_key_id: YOUR_CODE_FOR_S3_STORAGE
  secret_access_key: YOUR_CODE_FOR_S3_STORAGE
google_analytics: YOUR_CODE_FOR_GOOGLE_ANALYTICS
google_oauth2:
  client_id: YOUR_CODE_FOR_OAUTH
  client_secret: YOUR_CODE_FOR_OAUTH
development:
  github:
    client: YOUR_CODE_FOR_OAUTH
    secret: YOUR_CODE_FOR_OAUTH
  stripe:
    publishable: YOUR_STRIPE_PUBLISHABLE
    secret: YOUR_STRIPE_SECRET
production:
  github:
    client: YOUR_CODE_FOR_OAUTH
    secret: YOUR_CODE_FOR_OAUTH
  stripe:
    publishable: YOUR_STRIPE_PUBLISHABLE
    secret: YOUR_STRIPE_SECRET
facebook:
  client: YOUR_CODE_FOR_OAUTH
  secret: YOUR_CODE_FOR_OAUTH
smtp:
  address: email-smtp.eu-central-1.amazonaws.com
  user_name: SMTP_CREDENTIALS_USER_NAME
  password: SMTP_CREDENTIALS_PASSWORD
```

### 4. Setup database

```bash
rails db:create db:migrate
```

## Running the App Locally

### Option 1: Using bin/dev (Recommended)

This starts both the Rails server and Bun watcher with a single command:

```bash
bin/dev
```

The app will be available at `http://localhost:3000`

### Option 2: Run servers separately

In one terminal, start the Rails server:

```bash
rails server
```

In another terminal, start the Bun watcher for JavaScript:

```bash
bun run dev
```

The app will be available at `http://localhost:3000`

### Option 3: Without live asset reloading

If you don't need live reloading, you can compile assets once and run just the Rails server:

```bash
bun run build
rails server
```

## Connected Services

### Required for full functionality

- **Stripe** - Payment processing (development and production)
- **OAuth providers** - Google, GitHub, Facebook authentication

### Production only

- **AWS S3** - File storage
- **Amazon SES** - Email delivery
- **Google Analytics** - Usage tracking

## Running Tests

```bash
# All tests
rails test

# System tests (browser-based)
rails test:system

# Controller tests only
rails test test/controllers
```

## Deployment (Heroku)

```bash
heroku create
heroku rename your-app-name
heroku git:remote -a your-app-name
heroku buildpacks:add https://github.com/nickhstr/heroku-buildpack-bun.git
heroku buildpacks:add heroku/ruby
heroku config:set RAILS_MASTER_KEY=`cat config/master.key`
git push heroku main
heroku run rails db:migrate
```

## Useful Commands

### Rails console

```bash
rails c
```

### Creating an enrollment manually

```ruby
PublicActivity.enabled = false
Enrollment.create(user: User.find(id), course: Course.find(id), price: 0)
```

### Backfill Stripe IDs for existing courses

```ruby
Course.where(stripe_product_id: nil).each do |course|
  product = Stripe::Product.create(name: course.title)
  price = Stripe::Price.create(product: product, currency: "usd", unit_amount: course.price.to_i)
  course.update(stripe_product_id: product.id, stripe_price_id: price.id)
end
```

### Generate ERD diagram

```bash
bundle exec erd
```

## TODO

- Code linting improvements

## Video Tutorial

[![How to install](http://img.youtube.com/vi/nQd03MgXDXY/0.jpg)](http://www.youtube.com/watch?v=nQd03MgXDXY "Corsego e-learning platform: How to run locally")
