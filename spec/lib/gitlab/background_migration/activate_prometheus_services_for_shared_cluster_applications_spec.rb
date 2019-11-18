# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::BackgroundMigration::ActivatePrometheusServicesForSharedClusterApplications, :migration, schema: 2019_11_15_121407 do
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:services) { table(:services) }
  let(:clusters) { table(:clusters) }
  let(:cluster_groups) { table(:cluster_groups) }
  let(:clusters_applications_prometheus) { table(:clusters_applications_prometheus) }
  let(:columns) do
    %w(project_id active properties type template push_events
       issues_events merge_requests_events tag_push_events
       note_events category default wiki_page_events pipeline_events
       confidential_issues_events commit_events job_events
       confidential_note_events deployment_events)
  end

  def service_params_for(project)
    {
        project_id: project.id,
        active: true,
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

  def expected_rows(rows)
    rows.sort_by(&:id).map(&method(:service_params_for))
  end

  describe '#perform' do
    shared_examples 'skips non prometheus services' do
      let(:other_type) { 'SomeOtherService' }

      before do
        project_records.each { |proj| services.create(service_params_for(proj).merge(type: other_type)) }
      end

      it 'does not change them' do
        expect { subject.perform(start_id, stop_id) }.not_to change { services.where(type: other_type).order(:id).map { |row| row.attributes } }
      end
    end

    shared_examples 'skips configured manually prometheus services' do
      let(:properties) { '{"api_url":"http://test.dev","manual_configuration":"1"}' }

      before do
        project_records.each { |proj| services.create(service_params_for(proj).merge(properties: properties, active: false)) }
      end

      it 'does not change them' do
        expect { subject.perform(start_id, stop_id) }.not_to change { services.order(:id).map { |row| row.attributes } }
      end
    end

    shared_context 'prometheus integration services do not exist' do
      it 'creates missing services entries' do
        subject.perform(start_id, stop_id)

        rows = services.order(:id).map { |row| row.attributes.slice(*columns).symbolize_keys }

        expect(expected_rows(project_records)).to eq rows
      end
    end

    shared_context 'prometheus integration services exist' do
      context 'in active state' do
        before do
          project_records.each { |proj| services.create(service_params_for(proj)) }
        end

        it 'does not change them' do
          expect { subject.perform(start_id, stop_id) }.not_to change { services.order(:id).map { |row| row.attributes } }
        end
      end

      context 'not in active state' do
        before do
          project_records.each { |proj| services.create(service_params_for(proj).merge(active: false)) }
        end

        it 'sets active attribute to true' do
          rows_before = expected_rows(project_records).map { |row| row.merge(active: false) }

          expect { subject.perform(start_id, stop_id) }
              .to change { services.order(:id).map { |row| row.attributes.slice(*columns).symbolize_keys } }
                      .from(rows_before).to(expected_rows(project_records))
        end
      end
    end

    shared_context 'prometheus integrations partially missing services and outdated' do
      before do
        active_projects.each { |proj| services.create(service_params_for(proj)) }
        inactive_projects.each { |proj| services.create(service_params_for(proj).merge(active: false)) }
      end

      it 'fixes data state' do
        subject.perform(start_id, stop_id)

        rows = services.order(:project_id).map { |row| row.attributes.slice(*columns).symbolize_keys }

        expect(expected_rows(project_records)).to eq rows
      end

      it 'is idempotent' do
        subject.perform(start_id, stop_id)

        expect { subject.perform(start_id, stop_id) }.not_to change { services.order(:id).map { |row| row.attributes } }
      end
    end

    context 'group shared clusters' do
      let(:namespace) { namespaces.create(name: 'group', path: 'group') }
      let(:project) { projects.create(namespace_id: namespace.id) }
      let(:cluster) { clusters.create(name: 'cluster', cluster_type: 2) }
      let!(:project_records) { [project] }
      let(:start_id) { project.id }
      let(:stop_id) { project.id }

      before do
        cluster_groups.create(group_id: namespace.id, cluster_id: cluster.id)
        clusters_applications_prometheus.create(cluster_id: cluster.id, status: 3, version: '123')
      end

      it_behaves_like 'skips configured manually prometheus services'
      it_behaves_like 'skips non prometheus services'
      include_context 'prometheus integration services exist'
      include_context 'prometheus integration services do not exist'

      context 'with partially missing services' do
        let(:project2) { projects.create(namespace_id: namespace.id) }
        let(:project3) { projects.create(namespace_id: namespace.id) }
        let(:active_projects) { [project2] }
        let(:inactive_projects) { [project3] }
        let(:project_records) { [project, project2, project3].sort_by(&:id) }
        let(:start_id) { project_records[0].id }
        let(:stop_id) { project_records[-1].id }

        include_context 'prometheus integrations partially missing services and outdated'
      end
    end

    context 'instance shared cluster' do
      let(:namespace) { namespaces.create(name: 'user', path: 'user') }
      let(:project) { projects.create(namespace_id: namespace.id) }
      let(:cluster) { clusters.create(name: 'cluster', cluster_type: 1) }
      let!(:project_records) { [project] }
      let(:start_id) { project.id }
      let(:stop_id) { project.id }

      before do
        clusters_applications_prometheus.create(cluster_id: cluster.id, status: 3, version: '123')
      end

      it_behaves_like 'skips configured manually prometheus services'
      it_behaves_like 'skips non prometheus services'
      include_context 'prometheus integration services exist'
      include_context 'prometheus integration services do not exist'

      context 'with partially missing services' do
        let(:project2) { projects.create(namespace_id: namespace.id) }
        let(:project3) { projects.create(namespace_id: namespace.id) }
        let(:active_projects) { [project2] }
        let(:inactive_projects) { [project3] }
        let(:project_records) { [project, project2, project3].sort_by(&:id) }
        let(:start_id) { project_records[0].id }
        let(:stop_id) { project_records[-1].id }

        include_context 'prometheus integrations partially missing services and outdated'
      end
    end

    context 'both shared cluster types exist' do
      let(:namespace) { namespaces.create(name: 'user', path: 'user') }
      let(:project) { projects.create(namespace_id: namespace.id) }
      let(:cluster) { clusters.create(name: 'cluster', cluster_type: 1) }
      let(:group) { namespaces.create(name: 'group', path: 'group') }
      let(:group_project) { projects.create(namespace_id: group.id) }
      let(:group_cluster) { clusters.create(name: 'cluster', cluster_type: 2) }
      let!(:project_records) { [project, group_project] }
      let(:start_id) { project.id < group_project.id ? project.id : group_project.id }
      let(:stop_id) { project.id > group_project.id ? project.id : group_project.id }

      before do
        clusters_applications_prometheus.create(cluster_id: cluster.id, status: 3, version: '123')
        cluster_groups.create(group_id: namespace.id, cluster_id: group_cluster.id)
        clusters_applications_prometheus.create(cluster_id: group_cluster.id, status: 3, version: '123')
      end

      it_behaves_like 'skips configured manually prometheus services'
      it_behaves_like 'skips non prometheus services'
      include_context 'prometheus integration services exist'
      include_context 'prometheus integration services do not exist'

      context 'with partially missing services' do
        let(:project2) { projects.create(namespace_id: namespace.id) }
        let(:project3) { projects.create(namespace_id: namespace.id) }
        let(:group_project2) { projects.create(namespace_id: group.id) }
        let(:group_project3) { projects.create(namespace_id: group.id) }
        let(:active_projects) { [project2, group_project2] }
        let(:inactive_projects) { [project3, group_project3] }
        let(:project_records) { [project, group_project, project2, group_project2, project3, group_project3].sort_by(&:id) }
        let(:start_id) { project_records[0].id }
        let(:stop_id) { project_records[-1].id }

        include_context 'prometheus integrations partially missing services and outdated'
      end
    end
  end
end
