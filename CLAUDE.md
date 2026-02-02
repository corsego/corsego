# CLAUDE.md - AI Assistant Guide for Corsego

## Project Overview

Corsego is a **Udemy-like online learning platform** built with Ruby on Rails. It enables course creators (teachers) to publish and sell courses, while students can enroll, track progress, and leave reviews. The platform includes payment processing, multi-provider authentication, and role-based access control.

## Tech Stack

- **Backend**: Ruby 2.7.3, Rails 6.1.3.2
- **Database**: PostgreSQL
- **Frontend**: Webpacker 5, Bootstrap 4.5, jQuery, Turbolinks
- **Views**: HAML templates with Simple Form
- **Rich Text**: ActionText with Trix editor
- **Authentication**: Devise with OmniAuth (Google, GitHub, Facebook)
- **Authorization**: Pundit policies with Rolify roles
- **Payments**: Stripe (Checkout Sessions, Webhooks)
- **File Storage**: AWS S3 (production), local disk (development)
- **PDF Generation**: wicked_pdf with wkhtmltopdf

## Quick Commands

```bash
# Setup
bundle install
yarn install
rails db:create db:migrate

# Development
rails s                           # Start server
rails c                           # Rails console

# Database
rails db:migrate                  # Run migrations
rails db:rollback                 # Rollback last migration
rails db:seed                     # Seed database

# Testing
rails test                        # Run all tests
rails test test/controllers       # Run controller tests
rails test:system                 # Run system tests

# Linting
bundle exec rubocop               # Run RuboCop
bundle exec rubocop -a            # Auto-fix issues

# Assets
bundle exec rake webpacker:compile    # Compile JS assets
bundle exec rake assets:precompile    # Precompile all assets

# Utilities
bundle exec erd                   # Generate ERD diagram (requires graphviz)
```

## Project Structure

```
corsego/
├── app/
│   ├── controllers/          # Request handling
│   │   └── courses/          # Nested: course_wizard_controller.rb
│   ├── models/               # ActiveRecord models (13 total)
│   ├── views/                # HAML templates
│   ├── policies/             # Pundit authorization (8 policies)
│   ├── mailers/              # Email notifications (5 mailers)
│   ├── helpers/              # View helpers
│   ├── javascript/           # Webpacker entry points
│   │   ├── packs/            # application.js main entry
│   │   └── stylesheets/      # SCSS files
│   └── assets/               # Legacy asset pipeline (images, CSS)
├── config/
│   ├── routes.rb             # URL routing
│   ├── database.yml          # DB configuration
│   ├── storage.yml           # Active Storage config
│   └── initializers/         # Service configurations
├── db/
│   ├── schema.rb             # Current DB schema
│   ├── migrate/              # Database migrations
│   └── seeds.rb              # Seed data
├── test/                     # Minitest tests
│   ├── controllers/
│   ├── system/               # Browser tests
│   └── fixtures/             # Test data
└── Procfile                  # Heroku deployment
```

## Core Domain Models

### User
- Central model for all platform users
- Has roles: `admin`, `teacher`, `student` (via Rolify)
- Tracks: `balance`, `course_income`, `enrollment_expences`
- Relations: `has_many :courses, :enrollments, :comments, :user_lessons`

### Course
- Core content container created by teachers
- Has: `chapters` -> `lessons` (nested structure)
- Attributes: `title`, `price` (cents), `published`, `approved`
- Slug-based URLs via FriendlyId
- Rich text `description` via ActionText
- Stripe integration: `stripe_product_id`, `stripe_price_id`

### Lesson
- Individual learning unit within a chapter
- Supports: rich text content, Vimeo embeds
- Ordered via `ranked-model` (`row_order` column)
- Relations: `belongs_to :course, :chapter`; `has_many :comments`

### Enrollment
- Join model between User and Course
- Tracks: `rating`, `review`, `price` (paid)
- Created via Stripe webhook on successful payment

### Chapter
- Groups lessons within a course
- Ordered via `ranked-model`

## Key Controllers

| Controller | Purpose |
|------------|---------|
| `CoursesController` | CRUD + `learning`, `teaching`, `pending_review`, `analytics` |
| `LessonsController` | CRUD + `sort` for drag-drop ordering |
| `ChaptersController` | CRUD + `sort` for ordering |
| `EnrollmentsController` | CRUD + `teaching`, `certificate` (PDF) |
| `CheckoutController` | Creates Stripe Checkout Sessions |
| `WebhooksController` | Handles Stripe webhook events |
| `Courses::CourseWizardController` | Multi-step course creation (Wicked gem) |

## Routes Overview

```ruby
# Main resources
root -> static_pages#landing_page
resources :courses (nested: chapters, lessons, enrollments, course_wizard)
resources :enrollments
resources :users
resources :tags

# Nested under courses
/courses/:course_id/chapters
/courses/:course_id/lessons/:lesson_id/comments
/courses/:course_id/course_wizard (multi-step form)

# Stripe endpoints
POST /checkout/create
POST /webhooks/create

# Admin/analytics
GET /activity, /analytics
GET /charts/*
```

## Authentication & Authorization

### Devise Configuration
- Email/password with confirmation
- OmniAuth: Google, GitHub, Facebook
- Invitable for user invitations
- Invisible captcha (honeypot) on registration

### Role-Based Access (Rolify + Pundit)
```ruby
# Roles
:admin    # Full system access, can approve courses
:teacher  # Can create/edit own courses
:student  # Default role, can enroll in courses

# First user gets all roles; subsequent users get :teacher + :student
```

### Pundit Policies
- `CoursePolicy`: controls course CRUD, analytics, approval
- `LessonPolicy`: requires ownership, enrollment, or instructor status
- `EnrollmentPolicy`: controls reviews, certificates
- All controller actions should call `authorize @resource`

## Database Conventions

### Counter Caches
The app uses counter caches extensively for performance:
- `User`: courses_count, enrollments_count, comments_count
- `Course`: enrollments_count, lessons_count, chapters_count
- `Lesson`: comments_count, user_lessons_count
- `Tag`: course_tags_count

### Slug Generation (FriendlyId)
All main resources use slugs instead of IDs in URLs:
- User, Course, Lesson, Chapter, Enrollment

### Price Storage
Prices stored in **cents** (integer), not dollars:
```ruby
course.price = 9900  # $99.00
```

## External Service Integration

### Stripe
- Products and Prices created on course creation
- Checkout Sessions for payment flow
- Webhooks handle: `checkout.session.completed`, `customer.created`

### AWS S3 (Production)
- Course avatars, file uploads
- Configured in `config/storage.yml`

### Email (Amazon SES)
- Production SMTP via credentials
- Development uses `letter_opener` gem

## Frontend Patterns

### HAML Templates
Views use HAML, not ERB:
```haml
%h1= @course.title
.course-description
  = @course.description
```

### JavaScript
- Entry point: `app/javascript/packs/application.js`
- Uses: jQuery, Bootstrap, Turbolinks, Trix, Chartkick
- Sortable UI for drag-drop lesson/chapter ordering

### Forms
- Simple Form with Bootstrap integration
- Cocoon for nested attributes (chapters/lessons)
- Ransack for search/filter forms

## Code Style

### Ruby
- Frozen string literals: `# frozen_string_literal: true`
- RuboCop with Rails extension (see `.rubocop.yml`)
- Disabled cops: Documentation, MethodLength, AbcSize, LineLength

### Strong Parameters
All controllers use explicit permit lists:
```ruby
def course_params
  params.require(:course).permit(:title, :description, :price, ...)
end
```

## Testing

### Framework
- Minitest (Rails default)
- Parallel test execution enabled
- Devise test helpers included

### Running Tests
```bash
rails test                    # All tests
rails test test/controllers   # Controller tests only
rails test:system             # System/browser tests
```

### Test Files Location
- `test/controllers/` - Controller tests
- `test/system/` - Browser-based system tests
- `test/fixtures/` - Test data fixtures

## Common Development Tasks

### Adding a New Course Field
1. Generate migration: `rails g migration AddFieldToCourses field:type`
2. Run migration: `rails db:migrate`
3. Add to strong params in `CoursesController`
4. Update form in `app/views/courses/_form.html.haml`
5. Update policy if authorization needed

### Creating Enrollment Manually (Console)
```ruby
PublicActivity.enabled = false
Enrollment.create(user: User.find(id), course: Course.find(id), price: 0)
```

### Backfilling Stripe IDs for Existing Courses
```ruby
Course.where(stripe_product_id: nil).each do |course|
  product = Stripe::Product.create(name: course.title)
  price = Stripe::Price.create(product: product, currency: "usd", unit_amount: course.price.to_i)
  course.update(stripe_product_id: product.id, stripe_price_id: price.id)
end
```

## Credentials Setup

Credentials stored in `config/credentials.yml.enc`. Required keys:
```yaml
awss3:
  access_key_id: ...
  secret_access_key: ...
google_analytics: ...
google_oauth2:
  client_id: ...
  client_secret: ...
development:
  github: { client: ..., secret: ... }
  stripe: { publishable: ..., secret: ... }
production:
  github: { client: ..., secret: ... }
  stripe: { publishable: ..., secret: ... }
facebook: { client: ..., secret: ... }
smtp:
  address: email-smtp.eu-central-1.amazonaws.com
  user_name: ...
  password: ...
```

Edit with: `EDITOR=vim rails credentials:edit`

## Known Issues / TODOs

From README.md:
- Fix yarn/webpacker errors blocking deployment
- Bundle update and Rails upgrade needed
- Upgrade Puma to v5
- Make system tests work
- Code linting improvements
- Upgrade Ruby to 3.2.3
- Upgrade Heroku stack to 24

## Deployment (Heroku)

```bash
heroku create
heroku rename <app-name>
heroku git:remote -a <app-name>
heroku buildpacks:add heroku/nodejs
heroku config:set RAILS_MASTER_KEY=`cat config/master.key`
git push heroku master
heroku run rake db:migrate
```

## AI Assistant Guidelines

### When Making Changes
1. Always run `rails test` after changes to ensure nothing breaks
2. Follow existing code patterns (HAML views, Pundit policies, etc.)
3. Add authorization via Pundit for any new controller actions
4. Update counter caches if adding new associations
5. Use FriendlyId for user-facing resources

### Security Considerations
- All controller actions must be authorized via Pundit
- User input must go through strong parameters
- Prices stored in cents to avoid floating-point issues
- Stripe webhooks verify signatures

### Performance Notes
- Leverage counter caches instead of COUNT queries
- Use `includes` to avoid N+1 queries
- Pagination via Pagy (not Kaminari or will_paginate)
