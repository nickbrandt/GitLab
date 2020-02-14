# frozen_string_literal: true

require 'spec_helper'

describe Namespace do
  shared_examples 'plan helper' do |namespace_plan|
    let(:namespace) { create(:namespace, plan: "#{plan_name}_plan") }

    subject { namespace.public_send("#{namespace_plan}_plan?") }

    context "for a #{namespace_plan} plan" do
      let(:plan_name) { namespace_plan }

      it { is_expected.to eq(true) }
    end

    context "for a plan that isn't #{namespace_plan}" do
      where(plan_name: described_class::PLANS - [namespace_plan])

      with_them do
        it { is_expected.to eq(false) }
      end
    end
  end

  described_class::PLANS.each do |namespace_plan|
    describe "#{namespace_plan}_plan?" do
      it_behaves_like 'plan helper', namespace_plan
    end
  end

  describe '.reset_ci_minutes_in_batches!' do
    it 'returns when there were no failures' do
      expect { described_class.reset_ci_minutes_in_batches! }.not_to raise_error
    end

    it 'raises an exception when with a list of namespace ids to investigate if there were any failures' do
      failed_namespace = create(:namespace)

      allow(described_class).to receive(:transaction).and_raise(ActiveRecord::ActiveRecordError)

      expect { described_class.reset_ci_minutes_in_batches! }.to raise_error(
        EE::Namespace::NamespaceStatisticsNotResetError,
        "1 namespace shared runner minutes were not reset and the transaction was rolled back. Namespace Ids: [#{failed_namespace.id}]")
    end
  end

  describe '.reset_ci_minutes!' do
    it 'returns true if there were no exceptions to the db transaction' do
      result = described_class.reset_ci_minutes!([])

      expect(result).to be true
    end

    it 'raises an exception if anything in the transaction rolled back' do
      namespace = create(:namespace)

      allow(described_class).to receive(:transaction).and_raise(ActiveRecord::ActiveRecordError)

      expect { described_class.reset_ci_minutes!([namespace.id]) }.to raise_error(
        EE::Namespace::NamespaceStatisticsNotResetError,
        "1 namespace shared runner minutes were not reset and the transaction was rolled back. Namespace Ids: [#{namespace.id}]")
    end
  end

  describe '.recalculate_extra_shared_runners_minutes_limits!' do
    context 'when the namespace had used runner minutes for the month' do
      let(:namespace) { create(:namespace, shared_runners_minutes_limit: 5000, extra_shared_runners_minutes_limit: 5000) }

      it 'updates the namespace extra_shared_runners_minutes_limit subtracting used minutes above the shared_runners_minutes_limit' do
        minutes_used = 6000
        create(:namespace_statistics, namespace: namespace, shared_runners_seconds: minutes_used * 60)

        described_class.recalculate_extra_shared_runners_minutes_limits!([namespace.id])

        expect(namespace.reload.extra_shared_runners_minutes_limit).to eq(4000)
      end
    end
  end

  describe '.reset_shared_runners_seconds!' do
    let(:namespace) do
      create(:namespace,
        shared_runners_minutes_limit: 5000,
        extra_shared_runners_minutes_limit: 5000)
    end

    subject do
      described_class.reset_shared_runners_seconds!([namespace.id])
    end

    it 'resets NamespaceStatistics shared_runners_seconds and updates the timestamp' do
      namespace_statistics = create(:namespace_statistics,
        namespace: namespace,
        shared_runners_seconds: 360000 )

      expect { subject && namespace_statistics.reload }
        .to change { namespace_statistics.shared_runners_seconds }.to(0)
        .and change { namespace_statistics.shared_runners_seconds_last_reset }
    end

    it 'resets ProjectStatistics shared_runners_seconds and updates the timestamp' do
      project_statistics = create(:project_statistics,
        namespace: namespace,
        shared_runners_seconds: 120)

      expect { subject && project_statistics.reload }
        .to change { project_statistics.shared_runners_seconds }.to(0)
        .and change { project_statistics.shared_runners_seconds_last_reset }
    end
  end

  describe 'reset_ci_minutes_notifications!' do
    it 'updates the last_ci_minutes_notification_at and last_ci_minutes_usage_notification_level flags' do
      namespace = create(:namespace,
        last_ci_minutes_notification_at: Date.yesterday,
        last_ci_minutes_usage_notification_level: 50 )

      subject = described_class.reset_ci_minutes_notifications!([namespace.id])

      expect { subject && namespace.reload }
        .to change { namespace.last_ci_minutes_notification_at }.to(nil)
        .and change { namespace.last_ci_minutes_usage_notification_level }.to(nil)
    end
  end

  describe '#use_elasticsearch?' do
    let(:namespace) { create :namespace }

    it 'returns false if elasticsearch indexing is disabled' do
      stub_ee_application_setting(elasticsearch_indexing: false)

      expect(namespace.use_elasticsearch?).to eq(false)
    end

    it 'returns true if elasticsearch indexing enabled but limited indexing disabled' do
      stub_ee_application_setting(elasticsearch_indexing: true, elasticsearch_limit_indexing: false)

      expect(namespace.use_elasticsearch?).to eq(true)
    end

    it 'returns true if it is enabled specifically' do
      stub_ee_application_setting(elasticsearch_indexing: true, elasticsearch_limit_indexing: true)

      expect(namespace.use_elasticsearch?).to eq(false)

      create :elasticsearch_indexed_namespace, namespace: namespace

      expect(namespace.use_elasticsearch?).to eq(true)
    end
  end

  describe '#actual_plan_name' do
    let(:namespace) { create(:namespace, plan: :gold_plan) }

    subject { namespace.actual_plan_name }

    context 'when DB is read-only' do
      before do
        expect(Gitlab::Database).to receive(:read_only?) { true }
      end

      it 'returns free plan' do
        is_expected.to eq('free')
      end

      it 'does not create a gitlab_subscription' do
        expect { subject }.not_to change(GitlabSubscription, :count)
      end
    end

    context 'when namespace is not persisted' do
      let(:namespace) { build(:namespace, plan: :gold_plan) }

      it 'returns free plan' do
        is_expected.to eq('free')
      end

      it 'does not create a gitlab_subscription' do
        expect { subject }.not_to change(GitlabSubscription, :count)
      end
    end

    context 'when DB is not read-only' do
      it 'returns gold plan' do
        is_expected.to eq('gold')
      end

      it 'creates a gitlab_subscription' do
        expect { subject }.to change(GitlabSubscription, :count).by(1)
      end
    end
  end
end
