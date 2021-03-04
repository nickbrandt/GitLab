# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TrialStatusWidgetHelper do
  using RSpec::Parameterized::TableSyntax

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
    let(:user) { instance_double(User) }
    let(:group) { instance_double(Group, trial_active?: trial_active) }
    let(:user_can_admin_group) { true }

    before do
      allow(helper).to receive(:current_user).and_return(user)
      allow(helper).to receive(:can?).and_call_original
      allow(helper).to receive(:can?).with(user, :admin_namespace, group).and_return(user_can_admin_group)
    end

    subject { helper.eligible_for_trial_status_widget?(group) }

    where :trial_active, :user_can_admin_group, :expected_result do
      true  | true  | true
      true  | false | false
      false | true  | false
      false | false | false
    end

    with_them do
      it { is_expected.to eq(expected_result) }
    end
  end

  describe '#plan_title_for_group' do
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

  describe '#show_trial_status_widget?' do
    let(:group) { instance_double(Group) }

    before do
      allow(helper).to receive(:billing_plans_and_trials_available?).and_return(trials_available)
      allow(helper).to receive(:eligible_for_trial_status_widget?).with(group).and_return(eligible_for_widget)
    end

    subject { helper.show_trial_status_widget?(group) }

    where(:trials_available, :eligible_for_widget, :result) do
      true  | true  | true
      true  | false | false
      false | true  | false
      false | false | false
    end

    with_them do
      it { is_expected.to eq(result) }
    end
  end

  describe '#trial_status_widget_experiment_enabled?' do
    let(:experiment_key) { :show_trial_status_in_sidebar }
    let(:group) { instance_double(Group) }

    before do
      allow(helper).to receive(:experiment_enabled?).with(experiment_key, subject: group).and_return(experiment_enabled)
      allow(helper).to receive(:record_experiment_group)
    end

    subject { helper.trial_status_widget_experiment_enabled?(group) }

    context 'when the experiment is not enabled for the given group' do
      let(:experiment_enabled) { false }

      it { is_expected.to be_falsey }

      it 'records the group as an experiment participant' do
        expect(helper).to receive(:record_experiment_group).with(experiment_key, group)

        subject
      end
    end

    context 'when the experiment is enabled for the given group' do
      let(:experiment_enabled) { true }

      it { is_expected.to be_truthy }

      it 'records the group as an experiment participant' do
        expect(helper).to receive(:record_experiment_group).with(experiment_key, group)

        subject
      end
    end
  end
end
