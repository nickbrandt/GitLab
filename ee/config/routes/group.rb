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
    resource :ldap, only: [] do
      member do
        put :sync
      end
    end

    resource :issues_analytics, only: [:show]

    resource :notification_setting, only: [:update]

    resources :ldap_group_links, only: [:index, :create, :destroy]
    resources :audit_events, only: [:index]
    resources :pipeline_quota, only: [:index]

    resources :hooks, only: [:index, :create, :destroy], constraints: { id: /\d+/ } do
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
        get :discussions, format: :json
        get :realtime_changes
        post :toggle_subscription
      end

      resources :epic_issues, only: [:index, :create, :destroy, :update], as: 'issues', path: 'issues'
      resources :epic_links, only: [:index, :create, :destroy, :update], as: 'links', path: 'links'

      scope module: :epics do
        resources :notes, only: [:index, :create, :destroy, :update], concerns: :awardable, constraints: { id: /\d+/ }
      end
    end

    resources :todos, only: [:create]
    resources :boards, only: [:create, :update, :destroy]

    namespace :security do
      resource :dashboard, only: [:show], controller: :dashboard
      resources :vulnerabilities, only: [:index], controller: :vulnerabilities do
        collection do
          get :summary
          get :history
        end
      end
    end

    resource :saml_providers, path: 'saml', only: [:show, :create, :update] do
      post :callback, to: 'omniauth_callbacks#group_saml'
      get :sso, to: 'sso#saml'
      delete :unlink, to: 'sso#unlink'
    end

    resource :roadmap, only: [:show], controller: 'roadmap'

    legacy_ee_group_boards_redirect = redirect do |params, request|
      path = "/groups/#{params[:group_id]}/-/boards"
      path << "/#{params[:extra_params]}" if params[:extra_params].present?
      path << "?#{request.query_string}" if request.query_string.present?
      path
    end
    get 'boards(/*extra_params)', as: :legacy_ee_group_boards_redirect, to: legacy_ee_group_boards_redirect
  end

  scope(path: 'groups/*group_id') do
    Gitlab::Routing.redirect_legacy_paths(self, :analytics, :ldap, :ldap_group_links,
                                          :notification_setting, :audit_events,
                                          :pipeline_quota, :hooks, :boards)
  end
end
