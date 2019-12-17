# frozen_string_literal: true

require 'spec_helper'

describe ProjectHook do
  subject(:project_hook) { build(:project_hook, project: project) }

  let(:gold_plan) { create(:gold_plan) }
  let(:plan_limits) { create(:plan_limits, plan: gold_plan) }
  let(:namespace) { create(:namespace) }
  let(:project) { create(:project, namespace: namespace) }
  let!(:subscription) { create(:gitlab_subscription, namespace: namespace, hosted_plan: gold_plan) }

  context 'without plan limits configured' do
    it 'can create new project hooks' do
      expect { project_hook.save }.to change { described_class.count }
    end
  end

  context 'with plan limits configured' do
    before do
      plan_limits.update(project_hooks: 1)
    end

    it 'can create new project hooks' do
      expect { project_hook.save }.to change { described_class.count }
    end

    it 'cannot create new project hooks exceding the plan limits' do
      create(:project_hook, project: project)

      expect { project_hook.save }.not_to change { described_class.count }
      expect(project_hook.errors[:base]).to contain_exactly('Maximum number of project hooks (1) exceeded')
    end
  end
end
