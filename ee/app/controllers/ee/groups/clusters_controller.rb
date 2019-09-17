# frozen_string_literal: true

module EE
  module Groups
    module ClustersController
      extend ActiveSupport::Concern

      prepended do
        before_action :expire_etag_cache, only: [:show]
      end

      def environments
        respond_to do |format|
          format.json do
            ::Gitlab::PollingInterval.set_header(response, interval: 5_000)

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

      def expire_etag_cache
        return if request.format.json?

        # this forces to reload json content
        ::Gitlab::EtagCaching::Store.new.tap do |store|
          store.touch(environments_group_cluster_path(group, cluster))
        end
      end

      def serialize_environments(environments, request, response)
        ::Clusters::EnvironmentSerializer
          .new(cluster: cluster, current_user: current_user)
          .with_pagination(request, response)
          .represent(environments)
      end
    end
  end
end
