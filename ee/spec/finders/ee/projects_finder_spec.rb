# frozen_string_literal: true

require 'spec_helper'

describe ProjectsFinder do
  describe '#execute' do
    let(:finder) { described_class.new(current_user: user, params: params, project_ids_relation: project_ids_relation) }
    let(:user) { create(:user) }

    subject { finder.execute }

    describe 'filter by plans' do
      let(:params) { { plans: plans } }
      let(:project_ids_relation) { nil }
      let!(:gold_project) { create_project(:gold_plan) }
      let!(:gold_project2) { create_project(:gold_plan) }
      let!(:silver_project) { create_project(:silver_plan) }
      let!(:no_plan_project) { create_project(nil) }

      context 'with gold plan' do
        let(:plans) { ['gold'] }

        it { is_expected.to contain_exactly(gold_project, gold_project2) }
      end

      context 'with multiple plans' do
        let(:plans) { %w[gold silver] }

        it { is_expected.to contain_exactly(gold_project, gold_project2, silver_project) }
      end

      context 'with other plans' do
        let(:plans) { ['bronze'] }

        it { is_expected.to be_empty }
      end

      context 'without plans' do
        let(:plans) { nil }

        it { is_expected.to contain_exactly(gold_project, gold_project2, silver_project, no_plan_project) }
      end

      context 'with empty plans' do
        let(:plans) { [] }

        it { is_expected.to contain_exactly(gold_project, gold_project2, silver_project, no_plan_project) }
      end

      private

      def create_project(plan)
        namespace = create(:namespace_with_plan, plan: plan)
        namespace.update(plan: namespace.gitlab_subscription&.hosted_plan)

        create(:project, :public, namespace: namespace)
      end
    end
  end
end
