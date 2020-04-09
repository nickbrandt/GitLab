namespace :gitlab do
  namespace :seed do
    desc "GitLab | Metrics | Setup development metrics"
    task :development_metrics, [:project_id] => :gitlab_environment do |_, args|
      shared_multi_metrics_attributes = {
        title: 'Memory multi metric',
        y_label: 'Memory (GiB)',
        project_id: args.project_id,
        unit: 'GiB',
        group: 'system'
      }
      PrometheusMetric.find_or_create_by(
        **shared_multi_metrics_attributes,
        identifier: "#{args.project_id}-additional_system_metrics_container_memory_usage",
        legend: 'Usage (GiB)',
        query: 'avg(sum(container_memory_usage_bytes{id="/"}) by (job)) without (job) / 2^30'
      )
      PrometheusMetric.find_or_create_by(
        **shared_multi_metrics_attributes,
        identifier: "#{args.project_id}-additional_system_metrics_kube_node_status_capacity_memory_bytes",
        query: 'sum(kube_node_status_capacity_memory_bytes{kubernetes_namespace="gitlab-managed-apps"})/2^30',
        legend: 'Capacity (GiB)'
      )
      PrometheusMetric.find_or_create_by(
        **shared_multi_metrics_attributes,
        identifier: "#{args.project_id} additional_system_metrics_kube_pod_container_resource_requests_memory_bytes",
        query: 'sum(kube_pod_container_resource_requests_memory_bytes{kubernetes_namespace="gitlab-managed-apps"})/2^30',
        legend: 'Requested (GiB)'
      )
    end
  end
end
