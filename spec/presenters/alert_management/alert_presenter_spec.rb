# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AlertManagement::AlertPresenter do
  let_it_be(:project) { create(:project) }
  let_it_be(:generic_payload) do
    {
      'title' => 'Alert title',
      'start_time' => '2020-04-27T10:10:22.265949279Z',
      'custom' => { 'param' => 73 }
    }
  end
  let_it_be(:generic_alert) do
    create(:alert_management_alert, project: project, payload: generic_payload)
  end
  let_it_be(:prometheus_payload) do
    {
      'annotations' => {
        'title' => 'Alert title',
        'gitlab_incident_markdown' => '**`markdown example`**'
      },
      'startsAt' => '2020-04-27T10:10:22.265949279Z',
      'generatorURL' => 'http://8d467bd4607a:9090/graph?g0.expr=vector%281%29&g0.tab=1'
    }
  end
  let_it_be(:prometheus_alert) do
    create(:alert_management_alert, :prometheus, project: project, payload: prometheus_payload)
  end
  let(:alert) { generic_alert }
  let(:presenter) { described_class.new(alert) }

  describe '#issue_description' do
    let(:markdown_line_break) { '  ' }

    context 'with generic alert' do
      let(:alert) { generic_alert }
      let(:parsed_payload) { Gitlab::Alerting::NotificationPayloadParser.call(generic_payload.to_h) }
      let(:alert_presenter) { Gitlab::Alerting::Alert.new(project: project, payload: parsed_payload).present }

      it 'returns an alert issue description' do
        expect(presenter.issue_description).to eq(
          <<~MARKDOWN.chomp
            #### Summary

            **Start time:** #{alert_presenter.start_time}

            #### Alert Details

            **custom.param:** 73#{markdown_line_break}
            **severity:** critical
          MARKDOWN
        )
      end
    end

    context 'with prometheus alert' do
      let(:alert) { prometheus_alert }
      let(:alert_presenter) { Gitlab::Alerting::Alert.new(project: project, payload: prometheus_payload).present }

      it 'returns an alert issue description' do
        expect(presenter.issue_description).to eq(
          <<~MARKDOWN.chomp
            #### Summary

            **Start time:** #{alert_presenter.start_time}#{markdown_line_break}
            **full_query:** `vector(1)`


            ---

            **`markdown example`**
          MARKDOWN
        )
      end
    end
  end
end
