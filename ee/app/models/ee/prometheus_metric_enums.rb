# frozen_string_literal: true

module EE
  module PrometheusMetricEnums
    extend ActiveSupport::Concern

    class_methods do
      extend ::Gitlab::Utils::Override

      override :groups
      def groups
        super.merge(
          # Start at -100 to avoid collisions with CE values
          # built-in groups
          cluster_health: -100
        )
      end

      override :group_details
      def group_details
        super.merge(
          # keys can collide with CE values! please ensure you are not redefining a key that already exists in app/models/prometheus_metric_enums.rb#group_details
          # built-in groups
          cluster_health: {
            group_title: _('Cluster Health'),
            required_metrics: %w(container_memory_usage_bytes container_cpu_usage_seconds_total),
            priority: 10
          }
        )
      end
    end
  end
end
