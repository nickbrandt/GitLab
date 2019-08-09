# frozen_string_literal: true

module EE
  module Groups
    module ClustersController
      def environments
        respond_to do |format|
          format.json do
            environments = ::Clusters::EnvironmentsFinder.new(cluster, current_user).execute

            render json: serialize_environments(
              environments.preload_for_cluster_environment_entity,
              request,
              response
            )
          end
        end
      end

      private

      def serialize_environments(environments, request, response)
        ::Clusters::EnvironmentSerializer
          .new(cluster: cluster, current_user: current_user)
          .with_pagination(request, response)
          .represent(environments)
      end
    end
  end
end
