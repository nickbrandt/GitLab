# frozen_string_literal: true

require 'fast_spec_helper'

describe Gitlab::Alerting::NotificationPayloadParser do
  describe '.call' do
    subject { described_class.call(payload) }

    let(:starts_at) { Time.now.change(usec: 0) }
    let(:payload) do
      {
        'title' => 'alert title',
        'starts_at' => starts_at.rfc3339
      }
    end

    it 'returns Prometheus-like payload' do
      is_expected.to eq(
        {
          'annotations' => {
            'title' => 'alert title'
          },
          'startsAt' => starts_at.rfc3339
        }
      )
    end
  end
end
