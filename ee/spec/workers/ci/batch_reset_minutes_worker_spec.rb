# frozen_string_literal: true

require 'spec_helper'

describe Ci::BatchResetMinutesWorker do
  let(:worker) { described_class.new }

  describe '#perform' do
    let(:first_namespace) do
      create(:namespace,
        id: 1,
        shared_runners_minutes_limit: 100,
        extra_shared_runners_minutes_limit: 50,
        last_ci_minutes_notification_at: Time.now,
        last_ci_minutes_usage_notification_level: 30)
    end

    let(:last_namespace) do
      create(:namespace,
        id: 10,
        shared_runners_minutes_limit: 100,
        extra_shared_runners_minutes_limit: 50,
        last_ci_minutes_notification_at: Time.now,
        last_ci_minutes_usage_notification_level: 30)
    end

    let!(:first_namespace_statistics) do
      create(:namespace_statistics, namespace: first_namespace, shared_runners_seconds: 120.minutes)
    end

    let!(:last_namespace_statistics) do
      create(:namespace_statistics, namespace: last_namespace, shared_runners_seconds: 90.minutes)
    end

    include_examples 'an idempotent worker' do
      let(:job_args) { [first_namespace.id, last_namespace.id] }

      it 'delegates to Namespace method' do
        expect(Namespace).to receive(:reset_ci_minutes!).with([first_namespace, last_namespace]).twice

        subject
      end

      it 'resets CI minutes and recalculates purchased minutes for the namespace exceeding the monthly minutes' do
        subject

        first_namespace.reset
        first_namespace_statistics.reset
        expect(first_namespace.extra_shared_runners_minutes_limit).to eq 30
        expect(first_namespace_statistics.shared_runners_seconds).to eq 0
        expect(first_namespace.last_ci_minutes_notification_at).to be_nil
        expect(first_namespace.last_ci_minutes_usage_notification_level).to be_nil
      end

      it 'resets CI minutes but does not recalculate purchased minutes for the namespace not exceeding the monthly minutes' do
        subject

        last_namespace.reset
        last_namespace_statistics.reset
        expect(last_namespace.extra_shared_runners_minutes_limit).to eq 50
        expect(last_namespace_statistics.shared_runners_seconds).to eq 0
        expect(last_namespace.last_ci_minutes_notification_at).to be_nil
        expect(last_namespace.last_ci_minutes_usage_notification_level).to be_nil
      end
    end

    context 'when feature flag ci_parallel_minutes_reset is disabled' do
      before do
        stub_feature_flags(ci_parallel_minutes_reset: false)
      end

      it 'does not delegate to Namespace method' do
        expect(Namespace).not_to receive(:reset_ci_minutes!)

        worker.perform(first_namespace.id, last_namespace.id)
      end
    end
  end
end
