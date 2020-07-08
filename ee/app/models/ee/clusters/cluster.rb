# frozen_string_literal: true

module EE
  module Clusters
    module Cluster
      extend ActiveSupport::Concern

      prepended do
        include UsageStatistics
      end

      def prometheus_adapter
        application_prometheus
      end
    end
  end
end
