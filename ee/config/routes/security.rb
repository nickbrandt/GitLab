# frozen_string_literal: true

namespace :security do
  root to: 'dashboard#show'

  resource :dashboard, only: [:show], controller: :dashboard do
    get :settings
  end
  resources :projects, only: [:index, :create, :destroy]
  resources :vulnerabilities, only: [:index]
end
