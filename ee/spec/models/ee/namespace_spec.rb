# frozen_string_literal: true

require 'spec_helper'

describe Namespace do
  shared_examples 'plan helper' do |namespace_plan|
    let(:namespace) { described_class.new(plan: plan) }

    subject { namespace.public_send("#{namespace_plan}_plan?") }

    context "for a #{namespace_plan} plan" do
      let(:plan) { Plan.create(name: namespace_plan) }

      it { is_expected.to eq(true) }
    end

    context "for a plan that isn't #{namespace_plan}" do
      where(plan_name: described_class::PLANS - [namespace_plan])

      with_them do
        let(:plan) { Plan.create(name: plan_name) }

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

      ::Gitlab::CurrentSettings.update!(elasticsearch_namespace_ids: namespace.id.to_s)

      expect(namespace.use_elasticsearch?).to eq(true)
    end
  end

  describe '#paid_plan?' do
    using RSpec::Parameterized::TableSyntax

    let(:namespace) { create(:namespace) }

    before(:all) do
      %i[free_plan early_adopter_plan bronze_plan silver_plan gold_plan].each do |plan|
        create(plan)
      end
    end

    subject { namespace.paid_plan? }

    where(:plan_code, :expected_result) do
      described_class::FREE_PLAN          | false
      described_class::EARLY_ADOPTER_PLAN | false
      described_class::BRONZE_PLAN        | true
      described_class::SILVER_PLAN        | true
      described_class::GOLD_PLAN          | true
    end

    with_them do
      before do
        namespace.update!(gitlab_subscription_attributes: { hosted_plan: Plan.find_by_name(plan_code) })
      end

      it do
        is_expected.to eq(expected_result)
      end
    end
  end
end
