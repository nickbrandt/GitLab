# frozen_string_literal: true

require 'spec_helper'
require Rails.root.join('ee', 'db', 'migrate', '20180912113336_allow_prometheus_alerts_per_environment.rb')

describe AllowPrometheusAlertsPerEnvironment, :migration do
  let(:migration) { described_class.new }
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:environments) { table(:environments) }
  let(:prometheus_metrics) { table(:prometheus_metrics) }
  let(:prometheus_alerts) { table(:prometheus_alerts) }
  let(:now) { Time.now }

  let(:old_index_columns) { %i[project_id prometheus_metric_id] }
  let(:new_index_columns) { %i[project_id prometheus_metric_id environment_id] }
  let(:new_index_name) { described_class::INDEX_METRIC_ENVIRONMENT_NAME }

  describe '#up' do
    it 'creates a wider index dropping the narrower one' do
      migration.up

      expect(unique_index?(new_index_columns, name: new_index_name))
        .to eq(true)

      expect(unique_index?(old_index_columns)).to eq(false)
    end
  end

  describe '#down' do
    let(:ns) { namespace(id: 1, name: 'ns') }
    let(:a) { project(id: 1, name: 'a') }
    let(:b) { project(id: 2, name: 'b') }
    let(:c) { project(id: 3, name: 'c') }
    let(:a_prd) { environment(id: 11, name: 'a_prd', project: a) }
    let(:a_stg) { environment(id: 12, name: 'a_stg', project: a) }
    let(:a_can) { environment(id: 13, name: 'a_can', project: a) }
    let(:b_prd) { environment(id: 14, name: 'b_prd', project: b) }
    let(:b_stg) { environment(id: 15, name: 'b_stg', project: b) }
    let(:c_prd) { environment(id: 16, name: 'c_prd', project: c) }
    let(:metric_a) { metric(id: 21, project: a) }
    let(:metric_b) { metric(id: 22, project: b) }
    let(:metric_c) { metric(id: 23, project: c) }

    let(:alert_a_prd) { alert(id: 31, metric: metric_a, environment: a_prd) }
    let(:alert_a_stg) { alert(id: 32, metric: metric_a, environment: a_stg) }
    let(:alert_a_can) { alert(id: 33, metric: metric_a, environment: a_can) }
    let(:alert_b_stg) { alert(id: 34, metric: metric_b, environment: b_stg) }
    let(:alert_b_prd) { alert(id: 35, metric: metric_b, environment: b_prd) }
    let(:alert_c_prd) { alert(id: 36, metric: metric_c, environment: c_prd) }

    before do
      # Migration up to allow multiple alerts per environment
      schema_migrate_up!
    end

    it 'deletes duplicate alerts before narrowing the index' do
      # create
      alert_a_prd
      alert_a_stg
      alert_a_can
      alert_b_prd
      alert_b_stg
      alert_c_prd

      migration.down

      expect(unique_index?(old_index_columns, unique: true)).to eq(true)

      expect(unique_index?(new_index_columns, name: new_index_name))
        .to eq(false)

      expect(prometheus_alerts.all.to_a)
        .to contain_exactly(alert_a_prd, alert_b_stg, alert_c_prd)
    end
  end

  private

  def unique_index?(columns, opts = {})
    migration.index_exists?(:prometheus_alerts,
                            columns, opts.merge(unique: true))
  end

  def namespace(id:, name:)
    namespaces.create!(id: id, name: name, path: name)
  end

  def project(id:, name:)
    projects.create!(id: id, name: name, path: name, namespace_id: ns.id)
  end

  def environment(id:, name:, project:)
    environments.create!(id: id, name: name, slug: name,
                         project_id: project.id)
  end

  def metric(id:, project:)
    prometheus_metrics.create!(
      id: id,
      project_id: project.id,
      title: 'title',
      query: 'query',
      group: 1,
      created_at: now,
      updated_at: now,
      common: false
    )
  end

  def alert(id:, metric:, environment:)
    prometheus_alerts.create!(
      id: id,
      project_id: metric.project_id,
      environment_id: environment.id,
      prometheus_metric_id: metric.id,
      threshold: 1.0,
      operator: '=',
      created_at: now,
      updated_at: now
    )
  end
end
