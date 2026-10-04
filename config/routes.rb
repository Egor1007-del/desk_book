Rails.application.routes.draw do
  devise_for :users, skip: [ :registrations ]

  scope module: :web do
    root "home#index"
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
