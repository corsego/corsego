Rails.application.routes.draw do
  # devise_for :users
  devise_for :users, controllers: {registrations: "users/registrations",
                                   omniauth_callbacks: "users/omniauth_callbacks"}

  root "home#index"
  get "home/index"
  get "activity", to: "home#activity"
  get "analytics", to: "home#analytics"
  get "privacy_policy", to: "home#privacy_policy"

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
    resources :lessons, except: [:index] do
      resources :comments, except: [:index]
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
