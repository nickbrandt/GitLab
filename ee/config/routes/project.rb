# frozen_string_literal: true

constraints(::Constraints::ProjectUrlConstrainer.new) do
  scope(path: '*namespace_id',
        as: :namespace,
        namespace_id: Gitlab::PathRegex.full_namespace_route_regex) do
    scope(path: ':project_id',
          constraints: { project_id: Gitlab::PathRegex.project_route_regex },
          module: :projects,
          as: :project) do
      # Begin of the /-/ scope.
      # Use this scope for all new project routes.
      scope '-' do
        namespace :requirements_management do
          resources :requirements, only: [:index]
        end

        resources :feature_flags, param: :iid do
          resources :feature_flag_issues, only: [:index, :create, :destroy], as: 'issues', path: 'issues'
        end
        resource :feature_flags_client, only: [] do
          post :reset_token
        end
        resources :feature_flags_user_lists, param: :iid, only: [:new, :edit, :show]

        resources :autocomplete_sources, only: [] do
          collection do
            get 'epics'
          end
        end

        namespace :settings do
          resource :slack, only: [:destroy, :edit, :update] do
            get :slack_auth
          end
        end

        resources :subscriptions, only: [:create, :destroy]

        resource :threat_monitoring, only: [:show], controller: :threat_monitoring do
          resources :policies, only: [:new], controller: :threat_monitoring
        end

        resources :protected_environments, only: [:create, :update, :destroy], constraints: { id: /\d+/ } do
          collection do
            get 'search'
          end
        end

        resources :audit_events, only: [:index]

        namespace :security do
          resources :waf_anomalies, only: [] do
            get :summary, on: :collection
          end

          resources :network_policies, only: [:index, :create, :update, :destroy] do
            get :summary, on: :collection
          end

          resources :dashboard, only: [:index], controller: :dashboard

          resource :configuration, only: [:show], controller: :configuration do
            post :auto_fix, on: :collection
            resource :sast, only: [:show, :create], controller: :sast_configuration
          end

          resource :discover, only: [:show], controller: :discover

          resources :vulnerability_findings, only: [:index] do
            collection do
              get :summary
            end
          end

          resources :scanned_resources, only: [:index]

          resources :vulnerabilities, only: [:show] do
            member do
              get :discussions, format: :json
            end

            scope module: :vulnerabilities do
              resources :notes, only: [:index, :create, :destroy, :update], concerns: :awardable, constraints: { id: /\d+/ }
            end
          end
        end

        namespace :analytics do
          resources :code_reviews, only: [:index]
          resource :issues_analytics, only: [:show]
        end

        resources :approvers, only: :destroy
        resources :approver_groups, only: :destroy
        resources :push_rules, constraints: { id: /\d+/ }, only: [:update]
        resources :vulnerability_feedback, only: [:index, :create, :update, :destroy], constraints: { id: /\d+/ }
        resources :dependencies, only: [:index]
        resources :licenses, only: [:index, :create, :update]

        scope :on_demand_scans do
          root 'on_demand_scans#index', as: 'on_demand_scans'
          scope :profiles do
            root 'dast_profiles#index', as: 'profiles'
            resources :dast_site_profiles, only: [:new]
          end
        end

        namespace :integrations do
          namespace :jira do
            resources :issues, only: [:index]
          end
        end
      end
      # End of the /-/ scope.

      # All new routes should go under /-/ scope.
      # Look for scope '-' at the top of the file.
      # rubocop: disable Cop/PutProjectRoutesUnderScope

      resources :path_locks, only: [:index, :destroy] do
        collection do
          post :toggle
        end
      end

      resource :tracing, only: [:show]

      post '/restore' => '/projects#restore', as: :restore

      resource :insights, only: [:show], trailing_slash: true do
        collection do
          post :query
          get :embedded
        end
      end
      # All new routes should go under /-/ scope.
      # Look for scope '-' at the top of the file.
      # rubocop: enable Cop/PutProjectRoutesUnderScope
    end
  end
end

scope path: '(/-/jira)', constraints: ::Constraints::JiraEncodedUrlConstrainer.new, as: :jira do
  scope path: '*namespace_id/:project_id',
        namespace_id: Gitlab::Jira::Dvcs::ENCODED_ROUTE_REGEX,
        project_id: Gitlab::Jira::Dvcs::ENCODED_ROUTE_REGEX do
    get '/', to: redirect { |params, req|
      ::Gitlab::Jira::Dvcs.restore_full_path(
        namespace: params[:namespace_id],
        project: params[:project_id]
      )
    }

    get 'commit/:id', constraints: { id: /\h{7,40}/ }, to: redirect { |params, req|
      project_full_path = ::Gitlab::Jira::Dvcs.restore_full_path(
        namespace: params[:namespace_id],
        project: params[:project_id]
      )

      "/#{project_full_path}/commit/#{params[:id]}"
    }

    get 'tree/*id', as: nil, to: redirect { |params, req|
      project_full_path = ::Gitlab::Jira::Dvcs.restore_full_path(
        namespace: params[:namespace_id],
        project: params[:project_id]
      )

      "/#{project_full_path}/-/tree/#{params[:id]}"
    }
  end
end
