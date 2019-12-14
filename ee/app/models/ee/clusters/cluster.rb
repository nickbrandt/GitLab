# frozen_string_literal: true

module EE
  module Clusters
    module Cluster
      extend ActiveSupport::Concern

      prepended do
        prepend HasEnvironmentScope
        include UsageStatistics

        validate :unique_environment_scope
      end

      def prometheus_adapter
        application_prometheus
      end

      private

      def unique_environment_scope
        if clusterable.present? && clusterable.clusters.where(environment_scope: environment_scope).where.not(id: id).exists?
          errors.add(:environment_scope, 'cannot add duplicated environment scope')
        end
      end
    end
  end
end
