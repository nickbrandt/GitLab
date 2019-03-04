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
end
