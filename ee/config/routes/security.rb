# frozen_string_literal: true

namespace :security do
  root to: 'dashboard#show'
  get 'dasboard/settings', to: 'dashboard#settings', as: :settings_dashboard

  resources :projects, only: [:index, :create, :destroy]
  resources :vulnerable_projects, only: [:index]
end
