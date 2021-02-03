# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TrialStatusWidgetHelper do
  describe '#billing_plans_and_trials_available?' do
    before do
      stub_application_setting(check_namespace_plan: trials_available)
    end

    subject { helper.billing_plans_and_trials_available? }

    context 'when the check_namespace_plan ApplicationSetting is enabled' do
      let(:trials_available) { true }

      it { is_expected.to be_truthy }
    end

    context 'when the check_namespace_plan ApplicationSetting is disabled' do
      let(:trials_available) { false }

      it { is_expected.to be_falsey }
    end
  end

  describe '#eligible_for_trial_status_widget?' do
    let_it_be(:user) { create(:user) }
    let(:group) { instance_double(Group, trial_active?: trial_active) }
    let(:user_can_admin_group) { true }

    before do
      allow(helper).to receive(:current_user).and_return(user)
      allow(helper).to receive(:can?).and_call_original
      allow(helper).to receive(:can?).with(user, :admin_namespace, group).and_return(user_can_admin_group)
    end

    subject { helper.eligible_for_trial_status_widget?(group) }

    context 'when the group has an active trial' do
      let(:trial_active) { true }

      context 'and the user can admin the group' do
        let(:user_can_admin_group) { true }

        it { is_expected.to be_truthy }
      end

      context 'but the user cannot admin the group' do
        let(:user_can_admin_group) { false }

        it { is_expected.to be_falsey }
      end
    end

    context 'when the group does not have an active trial' do
      let(:trial_active) { false }

      it { is_expected.to be_falsey }
    end
  end

  describe '#plan_title_for_group' do
    using RSpec::Parameterized::TableSyntax

    let_it_be(:group) { create(:group) }

    subject { helper.plan_title_for_group(group) }

    where(:plan, :title) do
      :bronze   | 'Bronze'
      :silver   | 'Silver'
      :gold     | 'Gold'
      :premium  | 'Premium'
      :ultimate | 'Ultimate'
    end

    with_them do
      let!(:subscription) { build(:gitlab_subscription, plan, namespace: group) }

      it { is_expected.to eq(title) }
    end
  end
end
