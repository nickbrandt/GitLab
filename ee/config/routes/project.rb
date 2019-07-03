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
        resources :packages, only: [:index, :show, :destroy], module: :packages
        resources :package_files, only: [], module: :packages do
          member do
            get :download
          end
        end

        resources :jobs, only: [], constraints: { id: /\d+/ } do
          member do
            get '/proxy.ws/authorize', to: 'jobs#proxy_websocket_authorize', constraints: { format: nil }
            get :proxy
          end
        end

        resource :feature_flags_client, only: [] do
          post :reset_token
        end

        resources :autocomplete_sources, only: [] do
          collection do
            get 'epics'
          end
        end

        namespace :settings do
          resource :operations, only: [:show, :update] do
            member do
              post :reset_alerting_token
            end
          end
        end

        resources :designs, only: [], constraints: { id: /\d+/ } do
          member do
            get '(*ref)', action: 'show', as: '', constraints: { ref: Gitlab::PathRegex.git_reference_regex }
          end
        end
      end
      # End of the /-/ scope.

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

      resources :merge_requests, only: [], constraints: { id: /\d+/ } do
        member do
          get :metrics_reports
        end
      end

      resource :insights, only: [:show] do
        collection do
          post :query
        end
      end

      resource :dependencies, only: [:show]

      namespace :security do
        resources :dependencies, only: [:index]
      end
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
