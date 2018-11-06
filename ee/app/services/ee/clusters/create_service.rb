module EE
  module Clusters
    module CreateService
      extend ::Gitlab::Utils::Override

      override :can_create_cluster?
      def can_create_cluster?
        super || clusterable.feature_available?(:multiple_clusters)
      end
    end
  end
end
