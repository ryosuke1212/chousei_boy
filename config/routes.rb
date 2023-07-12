Rails.application.routes.draw do
  root 'static_pages#index'
  get '/terms', to: 'static_pages#terms'
  get '/privacy_policy', to: 'static_pages#privacy_policy'
  post '/callback' => 'linebot#callback'
  resources :schedules, only: [:index, :create, :destroy, :edit, :update, :show], param: :url_token
  devise_for :users, controllers: {
    omniauth_callbacks: "omniauth_callbacks"
  }
end
