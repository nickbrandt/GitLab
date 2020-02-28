# frozen_string_literal: true

require 'spec_helper'

describe GroupHook do
  describe "Associations" do
    it { is_expected.to belong_to :group }
  end

  describe 'validations' do
    subject(:group_hook) { build(:group_hook, group: group) }

    let(:gold_plan) { create(:gold_plan) }
    let(:plan_limits) { create(:plan_limits, plan: gold_plan) }
    let(:group) { create(:group) }
    let!(:subscription) { create(:gitlab_subscription, namespace: group, hosted_plan: gold_plan) }

    context 'without plan limits configured' do
      it 'can create new group hooks' do
        expect { group_hook.save }.to change { described_class.count }
      end
    end

    context 'with plan limits configured' do
      before do
        plan_limits.update(group_hooks: 1)
      end

      it 'can create new group hooks' do
        expect { group_hook.save }.to change { described_class.count }
      end

      it 'cannot create new group hooks exceding the plan limits' do
        create(:group_hook, group: group)

        expect { group_hook.save }.not_to change { described_class.count }
        expect(group_hook.errors[:base]).to contain_exactly('Maximum number of group hooks (1) exceeded')
      end
    end
  end
end
