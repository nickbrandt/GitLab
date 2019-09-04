# frozen_string_literal: true

require 'fast_spec_helper'

describe Gitlab::Alerting::NotificationPayloadParser do
  describe '.call' do
    let(:starts_at) { Time.current.change(usec: 0) }
    let(:payload) do
      {
        'title' => 'alert title',
        'start_time' => starts_at.rfc3339,
        'description' => 'Description',
        'monitoring_tool' => 'Monitoring tool name',
        'service' => 'Service',
        'hosts' => ['gitlab.com']
      }
    end

    subject { described_class.call(payload) }

    it 'returns Prometheus-like payload' do
      is_expected.to eq(
        {
          'annotations' => {
            'title' => 'alert title',
            'description' => 'Description',
            'monitoring_tool' => 'Monitoring tool name',
            'service' => 'Service',
            'hosts' => ['gitlab.com']
          },
          'startsAt' => starts_at.rfc3339
        }
      )
    end

    context 'when title is blank' do
      before do
        payload[:title] = ''
      end

      it 'sets a predefined title' do
        expect(subject['annotations']['title']).to eq('New: Incident')
      end
    end

    context 'when hosts attribute is a string' do
      before do
        payload[:hosts] = 'gitlab.com'
      end

      it 'returns hosts as an array of one element' do
        expect(subject['annotations']['hosts']).to eq(['gitlab.com'])
      end
    end

    context 'when the time is in unsupported format' do
      before do
        payload[:start_time] = 'invalid/date/format'
      end

      it 'sets startsAt to a currurrent time in RFC3339 format' do
        expect(subject['startsAt']).to eq(starts_at.rfc3339)
      end
    end

    context 'when payload is blank' do
      let(:payload) { {} }

      it 'returns default parameters' do
        is_expected.to eq(
          'annotations' => { 'title' => 'New: Incident' },
          'startsAt' => starts_at.rfc3339
        )
      end
    end
  end
end
