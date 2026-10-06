Rails.application.routes.draw do
  devise_for :users, skip: [ :registrations ]

  scope module: :web do
    root "home#index"
    resources :users, only: %i[index show]
    resource :profile, only: %i[edit update]

    namespace :admin do
      resources :users
    end
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
