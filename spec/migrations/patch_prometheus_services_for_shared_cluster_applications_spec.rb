# frozen_string_literal: true

require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20191220102807_patch_prometheus_services_for_shared_cluster_applications.rb')

describe PatchPrometheusServicesForSharedClusterApplications, :migration, :sidekiq do
  RSpec::Matchers.define :be_scheduled_delayed_migration_with_array do |delay, expected|
    match do |migration|
      BackgroundMigrationWorker.jobs.any? do |job|
        job['args'][0] == migration &&
          RSpec::Matchers::BuiltIn::ContainExactly.new(expected).matches?(job['args'][1]) &&
            job['at'].to_i == (delay.to_i + Time.now.to_i)
      end
    end

    failure_message do |migration|
      "Migration `#{migration}` with args `#{expected.inspect}` " \
      'not scheduled in expected time!'
    end
  end

  let(:migration_class) { Gitlab::BackgroundMigration::ActivatePrometheusServicesForSharedClusterApplications }
  let(:migration_name) { migration_class.to_s.demodulize }
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:services) { table(:services) }
  let(:clusters) { table(:clusters) }
  let(:cluster_groups) { table(:cluster_groups) }
  let(:clusters_applications_prometheus) { table(:clusters_applications_prometheus) }
  let(:namespace) { namespaces.create!(name: 'gitlab', path: 'gitlab-org') }
  let(:project_with_missing_service) { projects.create!(name: 'gitlab', path: 'gitlab-ce', namespace_id: namespace.id) }
  let(:project_with_inactive_service) { projects.create!(name: 'gitlab', path: 'gitlab-ee', namespace_id: namespace.id) }
  let(:project_with_active_service) { projects.create!(name: 'gitlab', path: 'gitlab-ee', namespace_id: namespace.id) }
  let(:project_with_manual_active_service) { projects.create!(name: 'gitlab', path: 'gitlab-ee', namespace_id: namespace.id) }
  let(:project_with_manual_inactive_service) { projects.create!(name: 'gitlab', path: 'gitlab-ee', namespace_id: namespace.id) }
  let(:project_with_active_not_prometheus_service) { projects.create!(name: 'gitlab', path: 'gitlab-ee', namespace_id: namespace.id) }
  let(:project_with_inactive_not_prometheus_service) { projects.create!(name: 'gitlab', path: 'gitlab-ee', namespace_id: namespace.id) }

  def service_params_for(project)
    {
      project_id: project.id,
      active: false,
      properties: '{}',
      type: 'PrometheusService',
      template: false,
      push_events: true,
      issues_events: true,
      merge_requests_events: true,
      tag_push_events: true,
      note_events: true,
      category: 'monitoring',
      default: false,
      wiki_page_events: true,
      pipeline_events: true,
      confidential_issues_events: true,
      commit_events: true,
      job_events: true,
      confidential_note_events: true,
      deployment_events: false
    }
  end

  before do
    services.create(service_params_for(project_with_inactive_service).merge(active: false))
    services.create(service_params_for(project_with_active_service).merge(active: true))
    services.create(service_params_for(project_with_active_not_prometheus_service).merge(active: true, type: 'other'))
    services.create(service_params_for(project_with_inactive_not_prometheus_service).merge(active: false, type: 'other'))
    services.create(service_params_for(project_with_manual_inactive_service).merge(active: false, properties: { some: 'data' }.to_json))
    services.create(service_params_for(project_with_manual_active_service).merge(active: true, properties: { some: 'data' }.to_json))
  end

  shared_examples 'patch prometheus services post migration' do
    context 'prometheus application is installed on the cluster' do
      before do
        clusters_applications_prometheus.create(cluster_id: cluster.id, status: 3, version: '123')
      end

      it 'schedules a background migration' do
        Sidekiq::Testing.fake! do
          Timecop.freeze do
            background_migrations = [["ActivatePrometheusServicesForSharedClusterApplications", project_with_inactive_service.id],
                                     ["ActivatePrometheusServicesForSharedClusterApplications", project_with_active_not_prometheus_service.id],
                                     ["ActivatePrometheusServicesForSharedClusterApplications", project_with_inactive_not_prometheus_service.id]]

            migrate!

            enqueued_migrations = BackgroundMigrationWorker.jobs.map { |job| job['args'] }
            expect(enqueued_migrations).to match_array background_migrations
          end
        end
      end
    end

    context 'prometheus application is NOT installed on the cluster' do
      it 'does not schedule a background migration' do
        Sidekiq::Testing.fake! do
          Timecop.freeze do
            migrate!

            expect(BackgroundMigrationWorker.jobs.size).to eq 0
          end
        end
      end
    end
  end

  context 'Cluster is group_type' do
    let(:cluster) { clusters.create(name: 'cluster', cluster_type: 2) }

    before do
      cluster_groups.create(group_id: namespace.id, cluster_id: cluster.id)
    end

    it_behaves_like 'patch prometheus services post migration'
  end

  context 'Cluster is instance_type' do
    let(:cluster) { clusters.create(name: 'cluster', cluster_type: 1) }

    it_behaves_like 'patch prometheus services post migration'
  end
end
