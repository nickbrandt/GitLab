# frozen_string_literal: true

require 'spec_helper'

describe PlanLimits do
  let(:plan_limits) { create(:plan_limits) }
  let(:model) { ProjectHook }
  let(:count) { model.count }

  before do
    create(:project_hook)
  end

  context 'without plan limits configured' do
    describe '#exceeded?' do
      it 'does not exceed any relation offset' do
        expect(plan_limits.exceeded?(:project_hooks, model)).to be false
        expect(plan_limits.exceeded?(:project_hooks, count)).to be false
      end
    end
  end

  context 'with plan limits configured' do
    before do
      plan_limits.update!(project_hooks: 2)
    end

    describe '#exceeded?' do
      it 'does not exceed the relation offset' do
        expect(plan_limits.exceeded?(:project_hooks, model)).to be false
        expect(plan_limits.exceeded?(:project_hooks, count)).to be false
      end
    end

    context 'with boundary values' do
      before do
        create(:project_hook)
      end

      describe '#exceeded?' do
        it 'does exceed the relation offset' do
          expect(plan_limits.exceeded?(:project_hooks, model)).to be true
          expect(plan_limits.exceeded?(:project_hooks, count)).to be true
        end
      end
    end
  end
end
