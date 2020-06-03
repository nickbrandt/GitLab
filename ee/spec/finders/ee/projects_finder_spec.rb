# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProjectsFinder do
  describe '#execute' do
    let_it_be(:user) { create(:user) }
    let(:finder) { described_class.new(current_user: user, params: params, project_ids_relation: project_ids_relation) }

    subject { finder.execute }

    describe 'filter by plans' do
      let(:params) { { plans: plans } }
      let(:project_ids_relation) { nil }

      let_it_be(:gold_project) { create_project(:gold_plan) }
      let_it_be(:gold_project2) { create_project(:gold_plan) }
      let_it_be(:silver_project) { create_project(:silver_plan) }
      let_it_be(:no_plan_project) { create_project(nil) }

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
        create(:project, :public, namespace: create(:namespace_with_plan, plan: plan))
      end
    end
  end
end
