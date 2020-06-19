# frozen_string_literal: true

module Gitlab
  module UsageDataConcerns
    module Topology
      include Gitlab::Utils::UsageData

      JOB_TO_SERVICE_NAME = {
        'gitlab-rails' => 'web',
        'gitlab-sidekiq' => 'sidekiq',
        'gitlab-workhorse' => 'workhorse',
        'redis' => 'redis',
        'postgres' => 'postgres',
        'gitaly' => 'gitaly',
        'prometheus' => 'prometheus',
        'node' => 'node-exporter'
      }.freeze

      def topology_usage_data
        topology_data, duration = measure_duration do
          topology_all_data || {}
        end

        { topology: topology_data.merge(duration_s: duration) }
      end

      private

      # Returns either nil or a non-empty hash with data (i.e. nil elements removed)
      def topology_all_data
        alt_usage_data(fallback: nil) do
          with_prometheus_client do |client|
            response = client.query('{__name__ =~ "^gitlab_usage_ping:.+"}')

            other_metrics, node_specific_metrics = topology_extract_metrics_groups(response)

            {
              application_requests_per_hour: alt_usage_data { topology_app_requests_per_hour(other_metrics) },
              nodes: alt_usage_data(fallback: []) { topology_nodes(node_specific_metrics) }
            }.compact
          end
        end
      end

      # Splits up all metric data into those that are per-node and those that are not
      # node specific (i.e. global)
      def topology_extract_metrics_groups(all_metrics)
        metrics_groups = all_metrics.group_by do |hash|
          hash['metric']['instance'].present?
        end

        other_metrics = metrics_groups[false]
        node_specific_metrics = metrics_groups[true]

        [other_metrics, node_specific_metrics]
      end

      def topology_app_requests_per_hour(metrics)
        app_requests_per_second_metric = metrics.find do |metric|
          metric['metric']['__name__'] == 'gitlab_usage_ping:gitlab_workhorse_http_requests:rate1w'
        end

        return unless app_requests_per_second_metric

        (app_requests_per_second_metric['value'].last.to_f * 60 * 60).to_i
      end

      def topology_nodes(node_specific_metrics)
        # Normalize instance names so we can process data on a per-node basis
        metrics_by_node = node_specific_metrics.group_by { |h| drop_port(h['metric']['instance']) }

        metrics_by_node.map do |_node_name, node_data|
          topology_process_node_data(node_data).tap do |result|
            # turn hash with services as keys into list of hashes with service names as values
            result[:node_services] = result[:node_services].map do |service_name, service_data|
              service_data.merge(name: service_name)
            end
          end
        end
      end

      def topology_process_node_data(node_data)
        node_data.each_with_object({}) do |data, result|
          labels, value = [data['metric'], data['value'].last.to_i]
          metric_name = labels['__name__']
          job_name = labels['job']

          case metric_name
          when 'gitlab_usage_ping:node_memory_total_bytes:avg1w'
            result[:node_memory_total_bytes] = value
          when 'gitlab_usage_ping:node_cpus:count'
            result[:node_cpus] = value
          when /gitlab_usage_ping:node_service_/
            result[:node_services] ||= {}
            result[:node_services].deep_merge!(topology_node_service_data(metric_name, job_name, value))
          end
        end
      end

      def topology_node_service_data(metric_name, job_label, value)
        gitlab_service = JOB_TO_SERVICE_NAME[job_label]
        return {} unless gitlab_service

        case metric_name
        when 'gitlab_usage_ping:node_service_process_resident_memory_bytes:avg1w'
          { gitlab_service => { process_memory_rss: value } }
        when 'gitlab_usage_ping:node_service_process_unique_memory_bytes:avg1w'
          { gitlab_service => { process_memory_uss: value } }
        when 'gitlab_usage_ping:node_service_process_proportional_memory_bytes:avg1w'
          { gitlab_service => { process_memory_pss: value } }
        when 'gitlab_usage_ping:node_service_process:count'
          { gitlab_service => { process_count: value } }
        else
          {}
        end
      end

      def drop_port(instance)
        instance.gsub(/:.+$/, '')
      end
    end
  end
end
