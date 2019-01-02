# frozen_string_literal: true

class Gitlab::BackgroundMigration::UpdatePrometheusApplication
  class Project < ActiveRecord::Base
    self.table_name = 'projects'

    has_many :cluster_projects, class_name: 'ClustersProject'
    has_many :clusters, through: :cluster_projects, class_name: 'Cluster'
  end

  class Cluster < ActiveRecord::Base
    self.table_name = 'clusters'

    has_one :application_prometheus, class_name: 'Prometheus'
  end

  class ClustersProject < ActiveRecord::Base
    self.table_name = 'cluster_projects'

    belongs_to :cluster, class_name: 'Cluster'
    belongs_to :project, class_name: 'Project'
  end

  class Prometheus < ActiveRecord::Base
    self.table_name = 'clusters_applications_prometheus'
  end

  def perform(from, to)
    app_name = 'prometheus'
    now = Time.now

    project_prometheus(from, to).each do |project_id, app_id|
      ClusterUpdateAppWorker.perform_async(app_name, app_id, project_id, now)
    end
  end

  private

  def project_prometheus(from, to, &block)
    Project
      .joins(clusters: :application_prometheus)
      .where('clusters_applications_prometheus.id IN (?)', from..to)
      .pluck('projects.id, clusters_applications_prometheus.id')
  end
end
