# frozen_string_literal: true

constraints(::Constraints::GroupUrlConstrainer.new) do
  scope(path: 'groups/*id',
        controller: :groups,
        constraints: { id: Gitlab::PathRegex.full_namespace_route_regex, format: /(html|json|atom|ics)/ }) do
    scope(path: '-') do
      get :subgroups, as: :subgroups_group
    end
  end

  scope(path: 'groups/*group_id/-',
        module: :groups,
        as: :group,
        constraints: { group_id: Gitlab::PathRegex.full_namespace_route_regex }) do
    resources :group_members, only: [], concerns: :access_requestable do
      patch :override, on: :member
    end

    resource :analytics, only: [:show]
    resource :cycle_analytics, only: [:show]
    namespace :cycle_analytics do
      scope :events, controller: 'events' do
        get :issue
        get :plan
        get :code
        get :test
        get :review
        get :staging
        get :production
      end
    end

    resource :ldap, only: [] do
      member do
        put :sync
      end
    end

    resource :issues_analytics, only: [:show]

    resource :insights, only: [:show], trailing_slash: true do
      collection do
        post :query
      end
    end

    resource :notification_setting, only: [:update]

    resources :ldap_group_links, only: [:index, :create, :destroy]
    resources :audit_events, only: [:index]
    resources :usage_quotas, only: [:index]

    resources :hooks, only: [:index, :create, :edit, :update, :destroy], constraints: { id: /\d+/ } do
      member do
        post :test
      end
    end

    resources :autocomplete_sources, only: [] do
      collection do
        get 'members'
        get 'issues'
        get 'merge_requests'
        get 'labels'
        get 'epics'
        get 'commands'
        get 'milestones'
      end
    end

    resources :billings, only: [:index]
    resources :epics, concerns: :awardable, constraints: { id: /\d+/ } do
      member do
        get '/descriptions/:version_id/diff', action: :description_diff, as: :description_diff
        get :discussions, format: :json
        get :realtime_changes
        post :toggle_subscription
      end

      resources :epic_issues, only: [:index, :create, :destroy, :update], as: 'issues', path: 'issues'
      resources :epic_links, only: [:index, :create, :destroy, :update], as: 'links', path: 'links'

      scope module: :epics do
        resources :notes, only: [:index, :create, :destroy, :update], concerns: :awardable, constraints: { id: /\d+/ }
      end

      collection do
        post :bulk_update
      end
    end

    resources :issues, only: [] do
      collection do
        post :bulk_update
      end
    end

    resources :merge_requests, only: [] do
      collection do
        post :bulk_update
      end
    end

    resources :todos, only: [:create]
    resources :boards, only: [:create, :update, :destroy] do
      collection do
        get :recent
      end
    end

    namespace :security do
      resource :dashboard, only: [:show], controller: :dashboard
      resources :vulnerable_projects, only: [:index]

      resources :vulnerability_findings, only: [:index] do
        collection do
          get :summary
          get :history
        end
      end
    end

    resource :saml_providers, path: 'saml', only: [:show, :create, :update] do
      callback_methods = Rails.env.test? ? [:get, :post] : [:post]
      match :callback, to: 'omniauth_callbacks#group_saml', via: callback_methods
      get :sso, to: 'sso#saml'
      delete :unlink, to: 'sso#unlink'
    end

    resource :scim_oauth, only: [:show, :create], controller: :scim_oauth

    get :sign_up, to: 'sso#sign_up_form'
    post :sign_up, to: 'sso#sign_up'

    resource :roadmap, only: [:show], controller: 'roadmap'

    resource :dependency_proxy, only: [:show, :update]
    resources :packages, only: [:index]
  end
end

# Dependency proxy for containers
# Because docker adds v2 prefix to URI this need to be outside of usual group routes
scope format: false do
  get 'v2', to: proc { [200, {}, ['']] }

  constraints image: Gitlab::PathRegex.container_image_regex do
    get 'v2/*group_id/dependency_proxy/containers/*image/manifests/*tag' => 'groups/dependency_proxy_for_containers#manifest'
    get 'v2/*group_id/dependency_proxy/containers/*image/blobs/:sha' => 'groups/dependency_proxy_for_containers#blob'
  end
end
