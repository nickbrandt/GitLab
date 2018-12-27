# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::BackgroundMigration::UpdatePrometheusApplication, :migration, schema: 20181115140251 do
  let(:background_migration) { described_class.new }

  let(:projects) { table(:projects) }
  let(:clusters) { table(:clusters) }
  let(:cluster_projects) { table(:cluster_projects) }
  let(:prometheus) { table(:clusters_applications_prometheus) }
  let(:namespaces) { table(:namespaces) }
  let(:namespace) { namespaces.create!(id: 1, name: 'gitlab', path: 'gitlab') }

  describe '#perform' do
    around do |example|
      Timecop.freeze { example.run }
    end

    let(:app_name) { 'prometheus' }
    let(:now) { Time.now }

    let!(:project1) { create_project }
    let!(:project2) { create_project }
    let!(:cluster1) { create_cluster(project: project1) }
    let!(:cluster2) { create_cluster(project: project2) }
    let!(:prometheus1) { create_prometheus(cluster: cluster1) }
    let!(:prometheus2) { create_prometheus(cluster: cluster2) }

    it 'schedules prometheus updates' do
      expect(ClusterUpdateAppWorker)
        .to receive(:perform_async)
        .with(app_name, prometheus1.id, project1.id, now)
      expect(ClusterUpdateAppWorker)
        .to receive(:perform_async)
        .with(app_name, prometheus2.id, project2.id, now)

      background_migration.perform(prometheus1.id, prometheus2.id)
    end
  end

  private

  def create_project
    projects.create!(namespace_id: namespace.id)
  end

  def create_cluster(project:)
    cluster = clusters.create!(name: 'cluster')
    cluster_projects.create!(cluster_id: cluster.id, project_id: project.id)
    cluster
  end

  def create_prometheus(cluster:)
    prometheus.create!(
      cluster_id: cluster.id,
      status: 3,
      version: '1.2.3'
    )
  end
end
