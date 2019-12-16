# frozen_string_literal: true

scope "/-/push_from_secondary/:geo_node_id" do
  draw :git_http
end

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
        resources :packages, only: [:index, :show, :destroy], module: :packages
        resources :package_files, only: [], module: :packages do
          member do
            get :download
          end
        end

        resources :jobs, only: [], constraints: { id: /\d+/ } do
          member do
            get '/proxy.ws/authorize', to: 'jobs#proxy_websocket_authorize', format: false
            get :proxy
          end
        end

        resources :feature_flags
        resource :feature_flags_client, only: [] do
          post :reset_token
        end

        resources :autocomplete_sources, only: [] do
          collection do
            get 'epics'
          end
        end

        namespace :settings do
          resource :operations, only: [] do
            member do
              post :reset_alerting_token
            end
          end

          resource :slack, only: [:destroy, :edit, :update] do
            get :slack_auth
          end
        end

        resources :designs, only: [], constraints: { id: /\d+/ } do
          member do
            get '(*ref)', action: 'show', as: '', constraints: { ref: Gitlab::PathRegex.git_reference_regex }
          end
        end

        resources :subscriptions, only: [:create, :destroy]

        namespace :performance_monitoring do
          resources :dashboards, only: [:create]
        end

        resources :licenses, only: [:index, :create, :update]

        resource :threat_monitoring, only: [:show], controller: :threat_monitoring

        resources :logs, only: [:index] do
          collection do
            get :k8s
          end
        end

        resources :protected_environments, only: [:create, :update, :destroy], constraints: { id: /\d+/ } do
          collection do
            get 'search'
          end
        end

        resources :audit_events, only: [:index]

        resources :merge_requests, only: [], constraints: { id: /\d+/ } do
          member do
            get '/descriptions/:version_id/diff', action: :description_diff, as: :description_diff
            get :metrics_reports
            get :license_management_reports
            get :container_scanning_reports
            get :dependency_scanning_reports
            get :sast_reports
            get :dast_reports

            get :approvals
            post :approvals, action: :approve
            delete :approvals, action: :unapprove

            post :rebase
          end

          resources :approvers, only: :destroy
          delete 'approvers', to: 'approvers#destroy_via_user_id', as: :approver_via_user_id
          resources :approver_groups, only: :destroy

          scope module: :merge_requests do
            resources :drafts, only: [:index, :update, :create, :destroy] do
              collection do
                post :publish
                delete :discard
              end
            end
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

      namespace :prometheus do
        resources :alerts, constraints: { id: /\d+/ }, only: [:index, :create, :show, :update, :destroy] do
          post :notify, on: :collection
        end

        resources :metrics, constraints: { id: %r{[^\/]+} }, only: [] do
          post :validate_query, on: :collection
        end
      end

      post 'alerts/notify', to: 'alerting/notifications#create'

      resource :tracing, only: [:show]

      resources :web_ide_terminals, path: :ide_terminals, only: [:create, :show], constraints: { id: /\d+/, format: :json } do
        member do
          post :cancel
          post :retry
        end

        collection do
          post :check_config
        end
      end

      resources :issues, only: [], constraints: { id: /\d+/ } do
        member do
          get '/descriptions/:version_id/diff', action: :description_diff, as: :description_diff
          get '/designs(/*vueroute)', to: 'issues#designs', as: :designs, format: false
        end

        collection do
          post :export_csv
          get :service_desk
        end

        resources :issue_links, only: [:index, :create, :destroy], as: 'links', path: 'links'
      end

      get '/service_desk' => 'service_desk#show', as: :service_desk
      put '/service_desk' => 'service_desk#update', as: :service_desk_refresh

      resources :approvers, only: :destroy
      resources :approver_groups, only: :destroy
      resources :push_rules, constraints: { id: /\d+/ }, only: [:update]

      resources :pipelines, only: [] do
        member do
          get :security
          get :licenses
        end
      end

      resource :insights, only: [:show], trailing_slash: true do
        collection do
          post :query
        end
      end

      namespace :security do
        resource :dashboard, only: [:show], controller: :dashboard
        resource :configuration, only: [:show], controller: :configuration

        resources :dependencies, only: [:index]
        # We have to define both legacy and new routes for Vulnerability Findings
        # because they are loaded upon application initialization and preloaded by
        # web server.
        # TODO: remove this comment and `resources :vulnerabilities` when applicable
        # see https://gitlab.com/gitlab-org/gitlab/issues/33488
        resources :vulnerabilities, only: [:index] do
          collection do
            get :summary
          end
        end
        resources :vulnerability_findings, only: [:index] do
          collection do
            get :summary
          end
        end
      end

      resources :vulnerability_feedback, only: [:index, :create, :update, :destroy], constraints: { id: /\d+/ }

      resource :dependencies, only: [:show]
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

      "/#{project_full_path}/tree/#{params[:id]}"
    }
  end
end
