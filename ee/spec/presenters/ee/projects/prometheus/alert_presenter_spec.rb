# frozen_string_literal: true

require 'spec_helper'

describe Projects::Prometheus::AlertPresenter do
  let_it_be(:project) { create(:project) }

  let(:presenter) { described_class.new(alert) }
  let(:payload) { {} }
  let(:alert) { create(:alerting_alert, project: project, payload: payload) }

  describe '#issue_summary_markdown' do
    let(:markdown_line_break) { '  ' }

    subject { presenter.issue_summary_markdown }

    context 'with gitlab alert' do
      let(:gitlab_alert) { create(:prometheus_alert, project: project) }
      let(:metric_id) { gitlab_alert.prometheus_metric_id }
      let(:env_id) { gitlab_alert.environment_id }
      let(:starts_at) { '2018-03-12T09:06:00Z' }

      let(:expected_markdown) do
        <<~MARKDOWN.chomp
        #### Summary

        **Start time:** #{presenter.starts_at}#{markdown_line_break}
        **full_query:** `avg(metric) > 1.0`

        [](http://localhost/#{project.full_path}/prometheus/alerts/#{metric_id}/metrics_dashboard?end=2018-03-12T09%3A36%3A00Z&environment_id=#{env_id}&start=2018-03-12T08%3A36%3A00Z)
        MARKDOWN
      end

      before do
        payload['labels'] = { 'gitlab_alert_id' => metric_id }
      end

      context 'without a starting time available' do
        around do |example|
          Timecop.freeze(starts_at) { example.run }
        end

        it { is_expected.to eq(expected_markdown) }
      end

      context 'with a starting time available' do
        before do
          payload['startsAt'] = starts_at
        end

        it { is_expected.to eq(expected_markdown) }
      end
    end
  end
end
