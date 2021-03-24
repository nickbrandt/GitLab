# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Plan do
  describe '#paid?' do
    subject { plan.paid? }

    Plan.default_plans.each do |plan|
      context "when '#{plan}'" do
        let(:plan) { build("#{plan}_plan".to_sym) }

        it { is_expected.to be_falsey }
      end
    end

    Plan::PAID_HOSTED_PLANS.each do |plan|
      context "when '#{plan}'" do
        let(:plan) { build("#{plan}_plan".to_sym) }

        it { is_expected.to be_truthy }
      end
    end
  end

  describe '::PLANS_ELIGIBLE_FOR_TRIAL' do
    subject { ::Plan::PLANS_ELIGIBLE_FOR_TRIAL }

    it { is_expected.to eq(%w[default free]) }
  end

  describe '#customersdot_name' do
    subject(:customersdot_plan_name) { plan.customersdot_name }

    context 'when a GitLab plan has the same name as on CustomersDot (non-mapped plan)' do
      let(:plan) { create(:bronze_plan) }

      it 'returns that name' do
        expect(customersdot_plan_name).to eq(plan.name)
      end
    end

    context 'with a Premium plan' do
      let(:plan) { create(:premium_plan) }

      it 'returns the CustomersDot name' do
        expect(customersdot_plan_name).to eq('premium_saas')
      end
    end

    context 'with a Ultimate plan' do
      let(:plan) { create(:ultimate_plan) }

      it 'returns the CustomersDot name' do
        expect(customersdot_plan_name).to eq('ultimate_saas')
      end
    end
  end
end
