# frozen_string_literal: true

require 'spec_helper'

describe Projects::Prometheus::AlertPresenter do
  let_it_be(:project) { create(:project) }

  let(:presenter) { described_class.new(alert) }
  let(:payload) { {} }
  let(:alert) { create(:alerting_alert, project: project, payload: payload) }
  let(:markdown_line_break) { '  ' }
  let(:starts_at) { '2018-03-12T09:06:00Z' }

  describe '#issue_summary_markdown' do
    shared_examples_for 'markdown with metrics embed' do
      let(:expected_markdown) do
        <<~MARKDOWN.chomp
        #### Summary

        **Start time:** #{presenter.starts_at}#{markdown_line_break}
        **full_query:** `avg(metric) > 1.0`

        [](#{url})
        MARKDOWN
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

    subject { presenter.issue_summary_markdown }

    context 'for gitlab-managed prometheus alerts' do
      let(:gitlab_alert) { create(:prometheus_alert, project: project) }
      let(:metric_id) { gitlab_alert.prometheus_metric_id }
      let(:env_id) { gitlab_alert.environment_id }

      before do
        payload['labels'] = { 'gitlab_alert_id' => metric_id }
      end

      let(:url) { "http://localhost/#{project.full_path}/prometheus/alerts/#{metric_id}/metrics_dashboard?end=2018-03-12T09%3A36%3A00Z&environment_id=#{env_id}&start=2018-03-12T08%3A36%3A00Z" }

      it_behaves_like 'markdown with metrics embed'
    end

    context 'for alerts from a self-managed prometheus' do
      let!(:environment) { create(:environment, project: project, name: 'production') }
      let(:url) { "http://localhost/#{project.full_path}/-/environments/#{environment.id}/metrics_dashboard?embed_json=#{CGI.escape(embed_content.to_json)}&end=2018-03-12T09%3A36%3A00Z&start=2018-03-12T08%3A36%3A00Z" }

      let(:title) { 'title' }
      let(:y_label) { 'y_label' }
      let(:query) { 'avg(metric) > 1.0' }
      let(:embed_content) do
        {
          panel_groups: [{
            panels: [{
              type: 'line-graph',
              title: title,
              y_label: y_label,
              metrics: [{ query_range: query }]
            }]
          }]
        }
      end

      before do
        # Setup embed time range
        payload['startsAt'] = starts_at

        # Setup query
        payload['generatorURL'] = "http://host?g0.expr=#{CGI.escape(query)}"

        # Setup environment
        payload['labels'] ||= {}
        payload['labels']['gitlab_environment_name'] = 'production'

        # Setup chart title & axis labels
        payload['annotations'] ||= {}
        payload['annotations']['title'] = 'title'
        payload['annotations']['gitlab_y_label'] = 'y_label'
      end

      it_behaves_like 'markdown with metrics embed'

      context 'without y_label' do
        let(:y_label) { title }

        before do
          payload['annotations'].delete('gitlab_y_label')
        end

        it_behaves_like 'markdown with metrics embed'
      end

      context 'when not enough information is present for an embed' do
        let(:expected_markdown) do
          <<~MARKDOWN.chomp
          #### Summary

          **Start time:** #{presenter.starts_at}#{markdown_line_break}
          **full_query:** `avg(metric) > 1.0`

          MARKDOWN
        end

        context 'without title' do
          before do
            payload['annotations'].delete('title')
          end

          it { is_expected.to eq(expected_markdown) }
        end

        context 'without environment' do
          before do
            payload['labels'].delete('gitlab_environment_name')
          end

          it { is_expected.to eq(expected_markdown) }
        end

        context 'without full_query' do
          let(:expected_markdown) do
            <<~MARKDOWN.chomp
            #### Summary

            **Start time:** #{presenter.starts_at}

            MARKDOWN
          end

          before do
            payload.delete('generatorURL')
          end

          it { is_expected.to eq(expected_markdown) }
        end
      end
    end
  end
end
