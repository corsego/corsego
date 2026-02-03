# CLAUDE.md - AI Assistant Guide for Corsego

## Project Overview

Corsego is a **Udemy-like online learning platform** built with Ruby on Rails. It enables course creators (teachers) to publish and sell courses, while students can enroll, track progress, and leave reviews. The platform includes payment processing, multi-provider authentication, and role-based access control.

## Tech Stack

- **Backend**: Ruby 3.4.5, Rails 8.1
- **Database**: PostgreSQL
- **Frontend**: Bun 1.3.6 (JS + CSS bundler), PostCSS, Sprockets (asset serving), Bootstrap 4.5, jQuery, Hotwire (Turbo)
- **Views**: HAML templates with Simple Form
- **Rich Text**: ActionText with Trix editor
- **Authentication**: Devise with OmniAuth (Google, GitHub, Facebook)
- **Authorization**: Pundit policies with Rolify roles
- **Payments**: Stripe (Checkout Sessions, Webhooks)
- **File Storage**: AWS S3 (production), local disk (development)
- **PDF Generation**: Prawn (pure Ruby)

## Quick Commands

```bash
# Setup
bundle install
bun install
rails db:create db:migrate

# Development
rails s                           # Start server
rails c                           # Rails console
bun run dev                       # Watch JS and CSS files, rebuild on change

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
bun run build                     # Compile JS and CSS assets (development)
bun run build:production          # Compile JS and CSS assets (production)
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
│   ├── javascript/           # Source files (bundled by Bun/PostCSS)
│   │   ├── application.js    # Main JS entry point
│   │   └── application.css   # Main CSS entry point (modern CSS)
│   └── assets/               # Asset pipeline (Sprockets)
│       └── builds/           # Bun/PostCSS output (application.js, application.css)
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
- Entry point: `app/javascript/application.js`
- Uses: jQuery, Bootstrap, Hotwire Turbo, Trix, Chartkick
- Sortable UI for drag-drop lesson/chapter ordering
- Bundled with Bun's native bundler (no webpack)
- Output: `app/assets/builds/application.js`
- **CRITICAL**: Bundle must use `format: 'iife'` in `build.js` (see below)

#### Bun Bundler Configuration
The `build.js` file configures Bun's bundler. The `format: 'iife'` setting is **required** to prevent naming conflicts between libraries:

```javascript
const result = await Bun.build({
  // ...
  format: 'iife',  // DO NOT REMOVE - prevents Stimulus/Turbo fetch conflict
  // ...
});
```

**Why this matters**: Stimulus exports an internal helper function named `fetch` for its Multimap class. Without IIFE wrapping, this becomes a top-level function that conflicts with `window.fetch`, causing Turbo's HTTP requests to fail with `TypeError: map.get is not a function`. The IIFE wrapper isolates all internal functions within a closure.

### CSS
- Entry point: `app/javascript/application.css`
- Uses modern CSS features: custom properties (variables), nesting
- Processed by PostCSS with `postcss-import`, `postcss-nesting`, `autoprefixer`
- Bundled by Bun (via build.js) to `app/assets/builds/application.css`
- Imports npm packages from node_modules (Bootstrap, Trix, Selectize, jQuery UI)
- FontAwesome loaded via CDN in layout (font files don't work via npm import)

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
- ~~Fix yarn/webpacker errors blocking deployment~~ (DONE - migrated to Bun bundler)
- ~~Bundle update and Rails upgrade needed~~ (DONE - upgraded to Rails 8.1)
- ~~Upgrade Puma to v5~~ (DONE - upgraded to Puma 6)
- ~~Replace google_captcha with invisible_captcha~~ (DONE)
- Make system tests work
- Code linting improvements
- ~~Upgrade Ruby to 3.2.3~~ (DONE - upgraded to Ruby 3.4.5)
- ~~Upgrade Heroku stack to 24~~ (DONE - added app.json with heroku-24 stack)
- ~~Upgrade to Rails 8.1 and Ruby 3.4.5~~ (DONE)
- ~~Replace SCSS with modern CSS~~ (DONE - migrated to PostCSS with CSS custom properties and nesting)
- ~~Fix Turbo/Stimulus fetch conflict breaking forms~~ (DONE - added `format: 'iife'` to Bun build config)

## Deployment (Heroku)

```bash
heroku create
heroku rename <app-name>
heroku git:remote -a <app-name>
heroku buildpacks:add https://github.com/jakeg/heroku-buildpack-bun
heroku buildpacks:add heroku/ruby
heroku config:set RAILS_MASTER_KEY=`cat config/master.key`
git push heroku master
heroku run rake db:migrate
```

Note: The app uses Bun for package management, JavaScript bundling, and CSS bundling (via PostCSS). The `app.json` file is pre-configured with the Bun buildpack for Heroku deployments.

## AI Assistant Guidelines

### When Making Changes
1. Be pragmatic - favor simple, working solutions over perfect ones
2. Always run `rails test` after changes to ensure nothing breaks
3. Follow existing code patterns (HAML views, Pundit policies, etc.)
4. Add authorization via Pundit for any new controller actions
5. Update counter caches if adding new associations
6. Use FriendlyId for user-facing resources
7. **NEVER remove the `x86_64-linux` platform from Gemfile.lock** - CI runs on Linux and requires this platform. If you modify Gemfile.lock, ensure the platform is preserved. Run `bundle lock --add-platform x86_64-linux` if needed.

### Security Considerations
- All controller actions must be authorized via Pundit
- User input must go through strong parameters
- Prices stored in cents to avoid floating-point issues
- Stripe webhooks verify signatures

### Performance Notes
- Leverage counter caches instead of COUNT queries
- Use `includes` to avoid N+1 queries
- Pagination via Pagy (not Kaminari or will_paginate)
