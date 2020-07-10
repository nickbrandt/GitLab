# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EE::TrialHelper do
  using RSpec::Parameterized::TableSyntax

  describe '#namespace_options_for_select' do
    let_it_be(:user) { create :user }
    let_it_be(:group1) { create :group }
    let_it_be(:group2) { create :group }

    let(:trial_user_namespaces) { [] }
    let(:trial_group_namespaces) { [] }

    let(:generated_html) do
      grouped_options_for_select({
        'New' => [['Create group', 0]],
        'Groups' => trial_group_namespaces.map { |g| [g.name, g.id] },
        'Users' => trial_user_namespaces.map { |n| [n.name, n.id] }
      }, nil, prompt: 'Please select')
    end

    before do
      allow(helper).to receive(:trial_group_namespaces).and_return(trial_group_namespaces)
      allow(helper).to receive(:trial_user_namespaces).and_return(trial_user_namespaces)
    end

    subject { helper.namespace_options_for_select }

    where(can_trial_user: [true, false], can_trial_groups: [true, false])

    with_them do
      context "when the user’s namespace #{params[:can_trial_user] ? 'can be' : 'has already been'} trialed" do
        let(:trial_user_namespaces) { can_trial_user ? [user.namespace] : [] }

        context "and the user has #{params[:can_trial_groups] ? 'some groups which' : 'no groups or none of their groups'} can be trialed" do
          let(:trial_group_namespaces) { can_trial_groups ? [group1, group2] : [] }

          it { is_expected.to eq(generated_html) }
        end
      end
    end
  end

  describe '#trial_group_namespaces' do
    let_it_be(:user) { create :user }
    let(:no_groups) { [] }

    before do
      allow(helper).to receive(:current_user).and_return(user)
    end

    subject { helper.trial_group_namespaces.map(&:id) }

    context 'when the user is not an owner/maintainer of any groups' do
      it { is_expected.to eq(no_groups) }
    end

    context 'when the user is an owner/maintainer of some groups' do
      let_it_be(:group1) { create :group, name: 'Group 1' }
      let_it_be(:subgroup1) { create :group, parent: group1, name: 'Sub-Group 1' }
      let_it_be(:group2) { create :group, name: 'Group 2' }
      let_it_be(:subgroup2) { create :group, parent: group2, name: 'Sub-Group 2' }
      let_it_be(:subsubgroup1) { create :group, parent: subgroup2, name: 'Sub-Sub-Group 1' }

      let(:all_groups) { [group1, group2, subgroup1, subgroup2, subsubgroup1].map(&:id) }

      before do
        group1.add_owner(user)
        group2.add_maintainer(user)
      end

      context 'and none of the groups have subscriptions' do
        it { is_expected.to eq(all_groups) }
      end

      context 'and the groups have subscriptions' do
        let(:group1_traits) { nil }
        let(:subgroup1_traits) { nil }
        let(:group2_traits) { nil }
        let(:subgroup2_traits) { nil }
        let(:subsubgroup1_traits) { nil }

        let!(:subscription_group1) { create :gitlab_subscription, :free, *group1_traits, namespace: group1 }
        let!(:subscription_subgroup1) { create :gitlab_subscription, :free, *subgroup1_traits, namespace: subgroup1 }
        let!(:subscription_group2) { create :gitlab_subscription, :free, *group2_traits, namespace: group2 }
        let!(:subscription_subgroup2) { create :gitlab_subscription, :free, *subgroup2_traits, namespace: subgroup2 }
        let!(:subscription_subsubgroup1) { create :gitlab_subscription, :free, *subsubgroup1_traits, namespace: subsubgroup1 }

        context 'and none of the groups have been trialed yet' do
          it { is_expected.to eq(all_groups) }
        end

        context 'and some of the groups are being or have been trialed' do
          let(:group1_traits) { :active_trial }
          let(:subgroup1_traits) { :expired_trial }
          let(:subgroup2_traits) { :active_trial }

          let(:some_groups) { [group2, subsubgroup1].map(&:id) }

          it { is_expected.to eq(some_groups) }
        end

        context 'and all of the groups are being or have been trialed' do
          let(:group1_traits) { :expired_trial }
          let(:subgroup1_traits) { :active_trial }
          let(:group2_traits) { :expired_trial }
          let(:subgroup2_traits) { :active_trial }
          let(:subsubgroup1_traits) { :expired_trial }

          it { is_expected.to eq(no_groups) }
        end
      end
    end
  end

  describe '#trial_user_namespaces' do
    let_it_be(:user) { create :user }
    let(:user_eligible_for_trial_result) { [user.namespace] }
    let(:user_ineligible_for_trial_result) { [] }

    before do
      allow(helper).to receive(:current_user).and_return(user)
      allow(::Gitlab).to receive(:com?).and_return(true)
    end

    subject { helper.trial_user_namespaces }

    context 'when the user has no subscription on their namespace' do
      it { is_expected.to eq(user_eligible_for_trial_result) }
    end

    context 'when the user has a subscription on their namespace' do
      let(:traits) { nil }
      let!(:subscription) { create :gitlab_subscription, :free, *traits, namespace: user.namespace }

      context 'and the user has not yet trialed their namespace' do
        it { is_expected.to eq(user_eligible_for_trial_result) }
      end

      context 'and the user has already trialed their namespace' do
        let(:traits) { :expired_trial }

        it { is_expected.to eq(user_ineligible_for_trial_result) }
      end
    end
  end

  describe '#show_trial_errors?' do
    shared_examples 'shows errors based on trial generation result' do
      where(:trial_result, :expected_result) do
        nil                | nil
        { success: true }  | false
        { success: false } | true
      end

      with_them do
        it 'show errors when trial generation was unsuccessful' do
          expect(helper.show_trial_errors?(namespace, trial_result)).to eq(expected_result)
        end
      end
    end

    context 'when namespace is nil' do
      let(:namespace) { nil }

      it_behaves_like 'shows errors based on trial generation result'
    end

    context 'when namespace is valid' do
      let(:namespace) { build(:namespace) }

      it_behaves_like 'shows errors based on trial generation result'
    end

    context 'when namespace is invalid' do
      let(:namespace) { build(:namespace, name: 'admin') }

      where(:trial_result, :expected_result) do
        nil                | true
        { success: true }  | true
        { success: false } | true
      end

      with_them do
        it 'show errors regardless of trial generation result' do
          expect(helper.show_trial_errors?(namespace, trial_result)).to eq(expected_result)
        end
      end
    end
  end
end
