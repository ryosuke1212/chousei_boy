Rails.application.routes.draw do
  root 'static_pages#index'
  resources :schedules, only: [:index, :create, :destroy, :edit, :update]
  devise_for :users, controllers: {
    omniauth_callbacks: "omniauth_callbacks"
  }
end
