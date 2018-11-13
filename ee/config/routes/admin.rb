# frozen_string_literal: true

namespace :admin do
  resources :users, constraints: { id: %r{[a-zA-Z./0-9_\-]+} } do
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

  namespace :geo do
    resources :nodes, only: [:index, :create, :new, :edit, :update]

    resources :projects, only: [:index, :destroy] do
      member do
        post :recheck
        post :resync
        post :force_redownload
      end

      collection do
        post :recheck_all
        post :resync_all
      end
    end
  end

  get '/dashboard/stats', to: 'dashboard#stats'
end
