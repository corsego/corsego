Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  mount LetterOpenerWeb::Engine, at: "/letter_opener" if Rails.env.development?

  authenticate :user, ->(user) { user.has_role?(:admin) } do
    mount GoodJob::Engine, at: "/good_job"
  end

  devise_for :users, controllers: {confirmations: "users/confirmations",
                                   registrations: "users/registrations",
                                   sessions: "users/sessions",
                                   passwords: "users/passwords",
                                   omniauth_callbacks: "users/omniauth_callbacks"}

  root "static_pages#landing_page"

  get "activity", to: "static_pages#activity"
  get "analytics", to: "static_pages#analytics"
  get "privacy", to: "static_pages#privacy"
  get "terms", to: "static_pages#terms"
  get "about", to: "static_pages#about"

  get '/sitemap.xml', to: redirect("https://corsego-public.s3.eu-central-1.amazonaws.com/sitemap.xml")

  resources :enrollments do
    get :teaching, on: :collection
    member do
      get :certificate
    end
  end

  resources :tags, only: [:create, :index, :destroy]
  resources :courses, except: [:edit] do
    collection do
      get :learning
      get :pending_review
      get :teaching
      get :unapproved
    end
    member do
      get :analytics
      patch :approve
    end

    resources :chapters, except: [:index, :show] do
      put :sort
    end

    resources :lessons, except: [:index] do
      resources :comments, except: [:index, :show, :new, :edit, :update]
      put :sort
    end
    resources :enrollments, only: [:new, :create]
    resources :access_grants, only: [:new, :create], controller: "courses/access_grants"
    resources :course_wizard, controller: "courses/course_wizard"
  end
  resources :youtube, only: :show

  resources :users, only: [:index, :edit, :show, :update]

  # stripe
  post "checkout/create", to: "checkout#create"
  get "checkout/success", to: "checkout#success"
  post "webhooks/create", to: "webhooks#create"

  namespace :charts do
    get "users_per_day"
    get "enrollments_per_day"
    get "course_popularity"
    get "money_makers"
  end
end
