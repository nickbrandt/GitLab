# frozen_string_literal: true

module EE
  module ClusterableActions
    extend ::Gitlab::Utils::Override

    private

    override :multiple_clusters_available?
    def multiple_clusters_available?
      subject.feature_available?(:multiple_clusters)
    end
  end
end
