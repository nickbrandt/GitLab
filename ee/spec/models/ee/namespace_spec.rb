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
