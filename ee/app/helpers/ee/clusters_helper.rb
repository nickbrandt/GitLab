# frozen_string_literal: true

module EE
  module ClustersHelper
    extend ::Gitlab::Utils::Override

    override :has_multiple_clusters?
    def has_multiple_clusters?
      clusterable.feature_available?(:multiple_clusters)
    end
  end
end
