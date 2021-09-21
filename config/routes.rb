Rails.application.routes.draw do
  devise_for :users, controllers: {registrations: "users/registrations",
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
    get :learning, :pending_review, :teaching, :unapproved, on: :collection
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
      member do
        delete :delete_video
      end
    end
    resources :enrollments, only: [:new, :create]
    resources :course_wizard, controller: "courses/course_wizard"
  end
  resources :youtube, only: :show

  resources :users, only: [:index, :edit, :show, :update]

  # stripe
  post "checkout/create", to: "checkout#create"
  post "webhooks/create", to: "webhooks#create"

  namespace :charts do
    get "users_per_day"
    get "enrollments_per_day"
    get "course_popularity"
    get "money_makers"
  end
  # get 'charts/users_per_day', to: 'charts#users_per_day'
  # get 'charts/enrollments_per_day', to: 'charts#enrollments_per_day'
  # get 'charts/course_popularity', to: 'charts#course_popularity'
  # get 'charts/money_makers', to: 'charts#money_makers'
end
