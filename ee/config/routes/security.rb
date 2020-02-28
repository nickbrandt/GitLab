# frozen_string_literal: true

namespace :security do
  root to: 'dashboard#show'

  resources :projects, only: [:index, :create, :destroy]
  resources :vulnerable_projects, only: [:index]

  resources :vulnerability_findings, only: [:index] do
    collection do
      get :summary
      get :history
    end
  end
end
