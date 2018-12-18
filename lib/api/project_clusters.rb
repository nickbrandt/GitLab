# frozen_string_literal: true

module API
  class ProjectClusters < Grape::API
    include PaginationParams

    before { authenticate! }

    helpers do
      params :optional_add_params_ee do
        # EE::API::ProjectClusters would override this
      end

      # EE::API::ProjectClusters would override this
      def environment_scope
        '*'
      end
    end

    prepend EE::API::ProjectClusters

    params do
      requires :id, type: String, desc: 'The ID of the project'
    end
    resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      desc 'Get all clusters from the project' do
        detail 'This feature was introduced in GitLab 11.7.'
        success Entities::Cluster
      end
      params do
        use :pagination
      end
      get ':id/clusters' do
        authorize! :read_cluster, user_project

        present paginate(clusters_for_current_user), with: Entities::Cluster
      end

      desc 'Get specific cluster for the project' do
        detail 'This feature was introduced in GitLab 11.7.'
        success Entities::ClusterProject
      end
      params do
        requires :cluster_id, type: Integer, desc: 'The cluster ID'
      end
      get ':id/clusters/:cluster_id' do
        authorize! :read_cluster, cluster

        present cluster, with: Entities::ClusterProject
      end

      desc 'Adds an existing cluster' do
        detail 'This feature was introduced in GitLab 11.7.'
        success Entities::ClusterProject
      end
      params do
        requires :name, type: String, desc: 'Cluster name'
        requires :api_url, type: String, desc: 'URL to access the Kubernetes API'
        requires :token, type: String, desc: 'Token to authenticate against Kubernetes'
        optional :ca_cert, type: String, desc: 'TLS certificate (needed if API is using a self-signed TLS certificate)'
        optional :namespace, type: String, desc: 'Unique namespace related to Project'
        optional :rbac_enabled, type: Boolean, default: true, desc: 'Enable RBAC authorization type, defaults to true'
        use :optional_add_params_ee
      end
      post ':id/add_cluster' do
        authorize! :create_cluster, user_project

        new_cluster = ::Clusters::CreateService
          .new(current_user, create_cluster_params)
          .execute(access_token: token_in_session)
          .present(current_user: current_user)

        if new_cluster.persisted?
          present new_cluster, with: Entities::ClusterProject
        else
          render_validation_error!(new_cluster)
        end
      end

      desc 'Update an existing cluster' do
        detail 'This feature was introduced in GitLab 11.7.'
        success Entities::ClusterProject
      end
      params do
        requires :cluster_id, type: Integer, desc: 'The cluster ID'
        optional :name, type: String, desc: 'Cluster name'
        optional :api_url, type: String, desc: 'URL to access the Kubernetes API'
        optional :token, type: String, desc: 'Token to authenticate against Kubernetes'
        optional :ca_cert, type: String, desc: 'TLS certificate (needed if API is using a self-signed TLS certificate)'
        optional :namespace, type: String, desc: 'Unique namespace related to Project'
      end
      put ':id/clusters/:cluster_id' do
        authorize! :update_cluster, cluster

        update_service = Clusters::UpdateService.new(current_user, update_cluster_params)

        if update_service.execute(cluster)
          present cluster, with: Entities::ClusterProject
        else
          render_validation_error!(cluster)
        end
      end

      desc 'Remove a cluster' do
        detail 'This feature was introduced in GitLab 11.7.'
        success Entities::ClusterProject
      end
      params do
        requires :cluster_id, type: Integer, desc: 'The Cluster ID'
      end
      delete ':id/clusters/:cluster_id' do
        authorize! :admin_cluster, cluster

        destroy_conditionally!(cluster)
      end
    end

    helpers do
      def clusters_for_current_user
        @clusters_for_current_user ||= ClustersFinder.new(user_project, current_user, :all).execute
      end

      def cluster
        @cluster ||= clusters_for_current_user.find(params[:cluster_id])
      end

      def token_in_session
        session[GoogleApi::CloudPlatform::Client.session_key_for_token]
      end

      def create_cluster_params
        {
          name: declared_params[:name],
          enabled: true,
          environment_scope: environment_scope,
          provider_type: :user,
          platform_type: :kubernetes,
          cluster_type: :project,
          clusterable: user_project,
          platform_kubernetes_attributes: create_platform_kubernetes_params
        }
      end

      def create_platform_kubernetes_params
        kubernetes_params = { authorization_type: kubernetes_authorization_type }
        permitted_params = platform_kubernetes_params + [:authorization_type]

        kubernetes_params.merge(declared_params.slice(*permitted_params))
      end

      def update_cluster_params
        {
          platform_kubernetes_attributes: update_platform_kubernetes_params
        }.merge(cluster.managed? ? {} : { name: declared_params[:name] })
      end

      def update_platform_kubernetes_params
        permitted_params = if cluster.managed?
                             [:namespace]
                           else
                             platform_kubernetes_params
                           end

        declared_params.slice(*permitted_params)
      end

      def platform_kubernetes_params
        [:api_url, :token, :ca_cert, :namespace]
      end

      def kubernetes_authorization_type
        rbac_enabled = declared_params.fetch(:rbac_enabled, true)
        rbac_enabled ? authorization_types[:rbac] : authorization_types[:abac]
      end

      def authorization_types
        Clusters::Platforms::Kubernetes.authorization_types
      end
    end
  end
end
