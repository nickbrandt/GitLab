# frozen_string_literal: true

scope(module: :repositories, path: '*repository_path', format: false) do
  constraints(repository_path: Gitlab::PathRegex.repository_git_route_regex) do
    # Redirect browser requests
    get '/', to: 'redirects#redirect_web'

    # Git HTTP API
    scope(controller: :git_http) do
      get '/info/refs', action: :info_refs
      post '/git-upload-pack', action: :git_upload_pack
      post '/git-receive-pack', action: :git_receive_pack
    end

    # NOTE: LFS routes are exposed on all repository types, but we still check for
    # LFS availability on the repository container in LfsRequest#lfs_check_access!

    # Git LFS API (metadata)
    scope(path: 'info/lfs/objects', controller: :lfs_api) do
      post :batch
      post '/', action: :deprecated
      get '/*oid', action: :deprecated
    end

    scope(path: 'info/lfs') do
      resources :lfs_locks, controller: :lfs_locks_api, path: 'locks' do
        post :unlock, on: :member
        post :verify, on: :collection
      end
    end

    # GitLab LFS object storage
    scope(path: 'gitlab-lfs/objects/*oid', controller: :lfs_storage, constraints: { oid: /[a-f0-9]{64}/ }) do
      get '/', action: :download

      constraints(size: /[0-9]+/) do
        put '/*size/authorize', action: :upload_authorize
        put '/*size', action: :upload_finalize
      end
    end
  end

  # Redirect Git requests for `:repository_path/info/refs` to `:repository_path.git/info/refs`
  # This allows cloning a repository without the trailing `.git`
  constraints(repository_path: Gitlab::PathRegex.repository_route_regex) do
    git_http_handshake = lambda do |request|
      request.query_string.blank? ||
        request.query_string == 'service=git-upload-pack' ||
        request.query_string == 'service=git-receive-pack'
    end

    get '/info/refs', constraints: git_http_handshake, to: 'redirects#redirect_git'
  end
end
