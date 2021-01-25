# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Metrics::Subscribers::RackAttack, :request_store do
  let(:subscriber) { described_class.new }

  describe '.payload' do
    context 'when the request store is empty' do
      it 'returns empty data' do
        expect(described_class.payload).to eql(
          rack_attack_redis_count: 0,
          rack_attack_redis_duration_s: 0.0
        )
      end
    end

    context 'when the request store already has data' do
      before do
        Gitlab::SafeRequestStore[:rack_attack_instrumentation] = {
          rack_attack_redis_count: 10,
          rack_attack_redis_duration_s: 9.0
        }
      end

      it 'returns the accumulated data' do
        expect(described_class.payload).to eql(
          rack_attack_redis_count: 10,
          rack_attack_redis_duration_s: 9.0
        )
      end
    end
  end

  describe '#rack_attack' do
    it 'accumulates per-request RackAttack cache usage' do
      freeze_time do
        subscriber.rack_attack(
          ActiveSupport::Notifications::Event.new(
            'rack_attack.redis', Time.current, Time.current + 1.second, '1', { operation: 'fetch' }
          )
        )
        subscriber.rack_attack(
          ActiveSupport::Notifications::Event.new(
            'rack_attack.redis', Time.current, Time.current + 2.seconds, '1', { operation: 'write' }
          )
        )
        subscriber.rack_attack(
          ActiveSupport::Notifications::Event.new(
            'rack_attack.redis', Time.current, Time.current + 3.seconds, '1', { operation: 'read' }
          )
        )
      end

      expect(Gitlab::SafeRequestStore[:rack_attack_instrumentation]).to eql(
        rack_attack_redis_count: 3,
        rack_attack_redis_duration_s: 6.0
      )
    end
  end
end
