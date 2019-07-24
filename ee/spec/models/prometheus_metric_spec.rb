# frozen_string_literal: true

require 'spec_helper'

describe PrometheusMetric do
  subject { build(:prometheus_metric) }

  describe '#group_title' do
    shared_examples 'group_title' do |group, title|
      subject { build(:prometheus_metric, group: group).group_title }

      it "returns text #{title} for group #{group}" do
        expect(subject).to eq(title)
      end
    end

    it_behaves_like 'group_title', :cluster_health, 'Cluster Health'
  end

  describe '#priority' do
    using RSpec::Parameterized::TableSyntax

    where(:group, :priority) do
      :cluster_health | 10
    end

    with_them do
      before do
        subject.group = group
      end

      it { expect(subject.priority).to eq(priority) }
    end
  end

  describe '#required_metrics' do
    using RSpec::Parameterized::TableSyntax

    where(:group, :required_metrics) do
      :cluster_health | %w(container_memory_usage_bytes container_cpu_usage_seconds_total)
    end

    with_them do
      before do
        subject.group = group
      end

      it { expect(subject.required_metrics).to eq(required_metrics) }
    end
  end
end
