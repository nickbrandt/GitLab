# frozen_string_literal: true

require 'spec_helper'

describe Projects::Prometheus::AlertPresenter do
  set(:project) { create(:project) }

  let(:presenter) { described_class.new(alert) }
  let(:alert) { create(:alerting_alert, project: project) }

  describe '#project_full_path' do
    subject { presenter.project_full_path }

    it { is_expected.to eq(project.full_path) }
  end

  context 'with gitlab alert' do
    let(:gitlab_alert) { create(:prometheus_alert, project: project) }
    let(:metric_id) { gitlab_alert.prometheus_metric_id }

    let(:alert) do
      create(:alerting_alert, project: project, metric_id: metric_id)
    end

    describe '#email_subject' do
      let(:query_title) do
        "#{gitlab_alert.title} #{gitlab_alert.computed_operator} #{gitlab_alert.threshold} for 5 minutes"
      end

      let(:expected_subject) do
        "#{alert.environment.name} #{query_title}"
      end

      subject { presenter.email_subject }

      it { is_expected.to eq(expected_subject) }
    end

    describe '#metric_query' do
      subject { presenter.metric_query }

      it { is_expected.to eq(gitlab_alert.full_query) }
    end

    describe '#environment_name' do
      subject { presenter.environment_name }

      it { is_expected.to eq(alert.environment.name) }
    end

    describe '#performance_dashboard_link' do
      before do
        gitlab_alert.save!
      end

      let(:expected_link) do
        Gitlab::Routing.url_helpers
          .metrics_project_environment_url(project, alert.environment)
      end

      subject { presenter.performance_dashboard_link }

      it { is_expected.to eq(expected_link) }
    end
  end

  context 'without gitlab alert' do
    describe '#email_subject' do
      subject { presenter.email_subject }

      it { is_expected.to eq('') }
    end

    describe '#metric_query' do
      subject { presenter.metric_query }

      it { is_expected.to be_nil }
    end

    describe '#environment_name' do
      subject { presenter.environment_name }

      it { is_expected.to be_nil }
    end

    describe '#performance_dashboard_link' do
      let(:expected_link) do
        Gitlab::Routing.url_helpers.metrics_project_environments_url(project)
      end

      subject { presenter.performance_dashboard_link }

      it { is_expected.to eq(expected_link) }
    end
  end
end
