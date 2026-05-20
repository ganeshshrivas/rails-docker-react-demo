# frozen_string_literal: true

Rails.application.routes.draw do
  post '/signup', to: 'auth#signup'
  post '/login', to: 'auth#login'

  get '/me', to: 'users#me'

  resources :posts, only: %i[index show create update destroy]
end
