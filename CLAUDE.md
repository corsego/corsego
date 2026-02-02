# CLAUDE.md - AI Assistant Guide for Corsego

## Project Overview

Corsego is a **Udemy-like online learning platform** built with Ruby on Rails. It enables course creators (teachers) to publish and sell courses, while students can enroll, track progress, and leave reviews. The platform includes payment processing, multi-provider authentication, and role-based access control.

## Tech Stack

- **Backend**: Ruby 3.3.6, Rails 7.1.6
- **Database**: PostgreSQL
- **Frontend**: Shakapacker 7, Bootstrap 4.5, jQuery, Hotwire (Turbo)
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
bin/shakapacker                       # Compile JS assets
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
├── Procfile                  # Heroku deployment
└── app.json                  # Heroku app configuration (stack: heroku-24)
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
- Invitation sharing: `invite_token`, `invite_enabled` (Google Docs-style sharing)

### Lesson
- Individual learning unit within a chapter
- Supports: rich text content, Vimeo embeds
- Ordered via `ranked-model` (`row_order` column)
- Relations: `belongs_to :course, :chapter`; `has_many :comments`

### Enrollment
- Join model between User and Course
- Tracks: `rating`, `review`, `price` (paid), `invited` (boolean)
- Created via Stripe webhook on successful payment
- Can also be created via course invitation (free, `invited: true`)

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
| `CourseInvitationsController` | Course sharing: invite links, QR codes, email invites |

## Routes Overview

```ruby
# Main resources
root -> static_pages#landing_page
resources :courses (nested: chapters, lessons, enrollments, course_wizard, invitations)
resources :enrollments
resources :users
resources :tags

# Nested under courses
/courses/:course_id/chapters
/courses/:course_id/lessons/:lesson_id/comments
/courses/:course_id/course_wizard (multi-step form)
/courses/:course_id/invitations (sharing/invite management)

# Stripe endpoints
POST /checkout/create
POST /webhooks/create

# Admin/analytics
GET /activity, /analytics
GET /charts/*
```

## Course Invitation/Sharing

Teachers can share courses with others for free enrollment (Google Docs-style sharing):

### Features
- **Shareable link**: One secret token per course, toggle on/off
- **QR code**: Auto-generated for easy mobile sharing
- **Email invitations**: Send to multiple recipients
- **Auto-enrollment**: Non-registered users prompted to sign up, then auto-enrolled

### How It Works
```ruby
# Enable sharing and get link
course.generate_invite_token!
course.update(invite_enabled: true)
invite_url = course.invite_url(host: 'https://example.com')

# Validate token
course.valid_invite_token?('token_here')  # => true/false

# Create invited enrollment
Enrollment.create(user: user, course: course, price: 0, invited: true)
```

### Routes
- `GET /courses/:id/invitations` - Share management page
- `PATCH /courses/:id/invitations/toggle` - Enable/disable sharing
- `POST /courses/:id/invitations/regenerate_token` - Generate new link
- `POST /courses/:id/invitations/send_emails` - Send email invitations
- `GET /courses/:id/invitations/accept?token=xxx` - Accept invitation

### Analytics
The course analytics page shows enrollment breakdown (paid vs invited).

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

### Honeybadger (Error Monitoring)
- Error tracking and uptime monitoring
- Configured in `config/honeybadger.yml`
- API key via `HONEYBADGER_API_KEY` environment variable

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
- Uses: jQuery, Bootstrap, Hotwire Turbo, Trix, Chartkick
- Sortable UI for drag-drop lesson/chapter ordering
- Bundled with Shakapacker (webpack-based)

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
- Mocha for mocking/stubbing
- WebMock for HTTP request stubbing
- Devise test helpers included

### Running Tests
```bash
rails test                        # All tests
rails test test/controllers       # Controller tests only
rails test test/models            # Model tests only
rails test test/mailers           # Mailer tests only
rails test:system                 # System/browser tests
rails test test/path/to_test.rb   # Single test file
```

### Test Files Location
```
test/
├── controllers/          # Integration tests for controllers
├── models/               # Unit tests for models
├── mailers/              # Mailer tests
│   └── previews/         # Email previews (view at /rails/mailers)
├── system/               # Browser-based system tests
├── fixtures/             # Test data (YAML files)
└── test_helper.rb        # Test configuration
```

### Test Configuration (test_helper.rb)
- PublicActivity tracking disabled globally
- Stripe API stubbed via WebMock
- Shakapacker helpers stubbed to avoid asset compilation
- ActionMailer delivery suppressed

### Writing Tests

#### Controller Tests
```ruby
class MyControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:teacher)  # Load from fixtures
  end

  test 'unauthenticated user is redirected' do
    get protected_url
    assert_redirected_to new_user_session_url
  end

  test 'authorized user can access' do
    sign_in @user
    get protected_url
    assert_response :success
  end
end
```

#### Model Tests
```ruby
class CourseTest < ActiveSupport::TestCase
  test 'valid course with all required fields' do
    course = Course.new(title: 'Test', ...)
    assert course.valid?, course.errors.full_messages.join(', ')
  end

  test 'scope returns expected records' do
    assert_includes Course.published, courses(:published_course)
  end
end
```

#### Mailer Tests
```ruby
class MyMailerTest < ActionMailer::TestCase
  test 'email has correct recipient' do
    email = MyMailer.notify(user)
    assert_equal [user.email], email.to
  end
end
```

### Fixtures
- Located in `test/fixtures/`
- Use ERB for dynamic values: `<%= User.new.send(:password_digest, 'password') %>`
- Reference associations by name: `user: teacher`
- Update counter caches manually in fixtures

### Test Naming Conventions
- Use descriptive test names: `test 'user cannot enroll in own course'`
- Group related tests with comments: `# SHOW`, `# CREATE`, etc.
- Test both happy path and error cases

### Assertions Reference
```ruby
assert                          # Truthy
assert_not                      # Falsy
assert_equal expected, actual   # Equality
assert_nil                      # Nil check
assert_includes collection, item
assert_not_includes collection, item
assert_difference 'Model.count', 1 do ... end
assert_no_difference 'Model.count' do ... end
assert_response :success        # HTTP 200
assert_redirected_to path       # Redirect check
assert_enqueued_emails 2 do ... end
```

### Pragmatic Testing Guidelines
1. **Test behavior, not implementation** - Focus on what the code does, not how
2. **Test edge cases** - Invalid input, unauthorized access, missing data
3. **Keep tests fast** - Stub external services, minimize database writes
4. **One assertion concept per test** - But multiple assertions for same concept is OK
5. **Use fixtures for stable test data** - Avoid creating records in every test
6. **Test authorization** - Verify Pundit policies are enforced
7. **Test both success and failure paths** - Don't just test the happy path

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
- ~~Fix yarn/webpacker errors blocking deployment~~ (DONE - migrated to Shakapacker)
- ~~Bundle update and Rails upgrade needed~~ (DONE - upgraded to Rails 7.1.6)
- ~~Upgrade Puma to v5~~ (DONE - upgraded to Puma 6)
- ~~Replace google_captcha with invisible_captcha~~ (DONE)
- Make system tests work
- Code linting improvements
- ~~Upgrade Ruby to 3.2.3~~ (DONE - upgraded to Ruby 3.3.6)
- ~~Upgrade Heroku stack to 24~~ (DONE - added app.json with heroku-24 stack)

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
1. Be pragmatic - favor simple, working solutions over perfect ones
2. Always run `rails test` after changes to ensure nothing breaks
3. Follow existing code patterns (HAML views, Pundit policies, etc.)
4. Add authorization via Pundit for any new controller actions
5. Update counter caches if adding new associations
6. Use FriendlyId for user-facing resources

### Security Considerations
- All controller actions must be authorized via Pundit
- User input must go through strong parameters
- Prices stored in cents to avoid floating-point issues
- Stripe webhooks verify signatures

### Performance Notes
- Leverage counter caches instead of COUNT queries
- Use `includes` to avoid N+1 queries
- Pagination via Pagy (not Kaminari or will_paginate)
