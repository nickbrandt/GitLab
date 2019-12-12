# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::BackgroundMigration::ActivatePrometheusServicesForSharedClusterApplications, :migration, schema: 2019_11_15_121407 do
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:services) { table(:services) }
  let(:namespace) { namespaces.create(name: 'user', path: 'user') }
  let(:project) { projects.create(namespace_id: namespace.id) }
  let!(:project_records) { [project] }
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
    it 'is idempotent' do
      subject.perform(project_records.map(&:id))

      expect { subject.perform(project_records.map(&:id)) }.not_to change { services.order(:id).map { |row| row.attributes } }
    end

    context 'non prometheus services' do
      let(:other_type) { 'SomeOtherService' }

      before do
        project_records.each { |proj| services.create(service_params_for(proj).merge(type: other_type)) }
      end

      it 'does not change them' do
        expect { subject.perform(project_records.map(&:id)) }.not_to change { services.where(type: other_type).order(:id).map { |row| row.attributes } }
      end
    end

    context 'prometheus services are configured manually ' do
      let(:properties) { '{"api_url":"http://test.dev","manual_configuration":"1"}' }

      before do
        project_records.each { |proj| services.create(service_params_for(proj).merge(properties: properties, active: false)) }
      end

      it 'does not change them' do
        expect { subject.perform(project_records.map(&:id)) }.not_to change { services.order(:id).map { |row| row.attributes } }
      end
    end

    context 'prometheus integration services do not exist' do
      it 'creates missing services entries' do
        subject.perform(project_records.map(&:id))

        rows = services.order(:id).map { |row| row.attributes.slice(*columns).symbolize_keys }

        expect(expected_rows(project_records)).to eq rows
      end
    end

    context 'prometheus integration services exist' do
      context 'in active state' do
        before do
          project_records.each { |proj| services.create(service_params_for(proj)) }
        end

        it 'does not change them' do
          expect { subject.perform(project_records.map(&:id)) }.not_to change { services.order(:id).map { |row| row.attributes } }
        end
      end

      context 'not in active state' do
        before do
          project_records.each { |proj| services.create(service_params_for(proj).merge(active: false)) }
        end

        it 'sets active attribute to true' do
          rows_before = expected_rows(project_records).map { |row| row.merge(active: false) }

          expect { subject.perform(project_records.map(&:id)) }
            .to change { services.order(:id).map { |row| row.attributes.slice(*columns).symbolize_keys } }
              .from(rows_before).to(expected_rows(project_records))
        end
      end
    end

    context 'with partially missing services' do
      let(:project_with_active_service) { projects.create(namespace_id: namespace.id) }
      let(:project_with_inactive_service) { projects.create(namespace_id: namespace.id) }
      let(:project_records) { [project, project_with_active_service, project_with_inactive_service] }

      before do
        services.create(service_params_for(project_with_active_service))
        services.create(service_params_for(project_with_inactive_service).merge(active: false))
      end

      it 'updates not active service and inserts missing ones' do
        subject.perform(project_records.map(&:id))

        rows = services.order(:project_id).map { |row| row.attributes.slice(*columns).symbolize_keys }

        expect(expected_rows(project_records)).to eq rows
        expect(rows.size).to be 3
      end
    end
  end
end
