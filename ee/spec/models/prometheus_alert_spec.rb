# frozen_string_literal: true

require 'spec_helper'

describe PrometheusAlert do
  set(:project) { build(:project) }
  let(:metric) { build(:prometheus_metric) }

  describe '.distinct_projects' do
    let(:project1) { create(:project) }
    let(:project2) { create(:project) }

    before do
      create(:prometheus_alert, project: project1)
      create(:prometheus_alert, project: project1)
      create(:prometheus_alert, project: project2)
    end

    subject { described_class.distinct_projects.count }

    it 'returns a count of all distinct projects which have an alert' do
      expect(subject).to eq(2)
    end
  end

  describe 'operators' do
    it 'contains the correct equality operator' do
      expect(described_class::OPERATORS_MAP.values).to include('==')
      expect(described_class::OPERATORS_MAP.values).not_to include('=')
    end
  end

  describe 'associations' do
    it { is_expected.to belong_to(:project).required }
    it { is_expected.to belong_to(:environment).required }
  end

  describe 'project validations' do
    let(:environment) { build(:environment, project: project) }
    let(:metric) { build(:prometheus_metric, project: project) }

    subject do
      build(:prometheus_alert, prometheus_metric: metric, environment: environment, project: project)
    end

    context 'when environment and metric belongs same project' do
      it { is_expected.to be_valid }
    end

    context 'when environment belongs to different project' do
      let(:environment) { build(:environment) }

      it { is_expected.not_to be_valid }
    end

    context 'when metric belongs to different project' do
      let(:metric) { build(:prometheus_metric) }

      it { is_expected.not_to be_valid }
    end

    context 'when metric is common' do
      let(:metric) { build(:prometheus_metric, :common) }

      it { is_expected.to be_valid }
    end
  end

  describe '#full_query' do
    before do
      subject.operator = "gt"
      subject.threshold = 1
      subject.prometheus_metric = metric
    end

    it 'returns the concatenated query' do
      expect(subject.full_query).to eq("#{metric.query} > 1.0")
    end
  end

  describe 'embedded metrics' do
    let(:project) { create(:project) }
    let(:other_project) { create(:project) }
    let(:environment) { create(:environment, project: project) }
    let(:metric) { create(:prometheus_metric, project: project, legend: "QueryLegend") }
    let(:other_metric) { create(:prometheus_metric, project: other_project, legend: "OtherMetricLegend") }
    let(:blank_project_metric) do
      create(:prometheus_metric,
             project: nil,
             common: true,
             query: 'increase(sum(metric))',
             legend: "BlankMetricLegend")
    end

    subject do
      build(:prometheus_alert,
            prometheus_metric: metric,
            environment: environment,
            project: project,
            alert_query: "(!#{metric.id})")
    end

    it 'expands embedded metrics for same project metrics' do
      expect(subject.query).to include(metric.query)
      expect(subject.abbreviated_query).to include(metric.legend)
    end

    it 'expands embedded metrics for blank project metrics' do
      subject.alert_query = "(!#{blank_project_metric.id})"
      expect(subject.query).to include(blank_project_metric.query)
      expect(subject.abbreviated_query).to include(blank_project_metric.legend)
    end

    it 'will not expand metrics for other projects' do
      subject.alert_query = "(!#{other_metric.id})"
      expect(subject.query).not_to include(other_metric.query)
      expect(subject.abbreviated_query).not_to include(other_metric.legend)
      expect(subject.query).to match(/\(!#{other_metric.id}\)/)
    end
  end

  describe '#to_param' do
    before do
      subject.operator = "gt"
      subject.threshold = 1
      subject.prometheus_metric = metric
    end

    it 'returns the params of the prometheus alert' do
      expect(subject.to_param).to eq(
        "alert" => metric.title,
        "expr" => "#{metric.query} > 1.0",
        "for" => "5m",
        "labels" => {
          "gitlab" => "hook",
          "gitlab_alert_id" => metric.id
        })
    end
  end
end
