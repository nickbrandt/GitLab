# frozen_string_literal: true

namespace :admin do
  resources :users, only: [], constraints: { id: %r{[a-zA-Z./0-9_\-]+} } do
    member do
      post :reset_runners_minutes
    end
  end

  scope(path: 'groups/*id',
        controller: :groups,
        constraints: { id: Gitlab::PathRegex.full_namespace_route_regex, format: /(html|json|atom)/ }) do
    scope(as: :group) do
      post :reset_runners_minutes
    end
  end

  get :instance_review, to: 'instance_review#index'

  resource :push_rule, only: [:show, :update]
  resource :email, only: [:show, :create]
  resources :audit_logs, controller: 'audit_logs', only: [:index]

  resource :license, only: [:show, :new, :create, :destroy] do
    get :download, on: :member
  end

  # using `only: []` to keep duplicate routes from being created
  resource :application_settings, only: [] do
    match :templates, via: [:get, :patch]
    get :geo, to: "application_settings#geo_redirection"
  end

  namespace :geo do
    get '/' => 'nodes#index'

    resources :nodes, only: [:index, :create, :new, :edit, :update]

    resources :projects, only: [:index, :destroy] do
      member do
        post :reverify
        post :resync
        post :force_redownload
      end

      collection do
        post :reverify_all
        post :resync_all
      end
    end

    resource :settings, only: [:show, :update]

    resources :designs, only: [:index]

    resources :uploads, only: [:index, :destroy]
  end

  namespace :elasticsearch do
    post :enqueue_index
  end

  get '/dashboard/stats', to: 'dashboard#stats'
end
