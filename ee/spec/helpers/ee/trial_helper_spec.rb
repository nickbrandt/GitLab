# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EE::TrialHelper do
  using RSpec::Parameterized::TableSyntax

  describe '#namespace_options_for_select' do
    let_it_be(:user) { create :user }
    let_it_be(:group1) { create :group }
    let_it_be(:group2) { create :group }

    let(:expected_group_options) { [] }
    let(:expected_user_options) { [[user.namespace.name, user.namespace.id]] }
    let(:generated_html) do
      grouped_options_for_select({
        'New' => [['Create group', 0]],
        'Groups' => expected_group_options,
        'Users' => expected_user_options
      }, nil, prompt: 'Please select')
    end

    before do
      allow(helper).to receive(:trial_groups).and_return(expected_group_options)
      allow(helper).to receive(:trial_users).and_return(expected_user_options)
    end

    subject { helper.namespace_options_for_select }

    context 'when the user’s namespace can be trialed' do
      context 'and the user has no groups or none of their groups can be trialed' do
        it { is_expected.to eq(generated_html) }
      end

      context 'and the user has some groups which can be trialed' do
        let(:expected_group_options) { [group1, group2].map {|g| [g.name, g.id]} }

        it { is_expected.to eq(generated_html) }
      end
    end

    context 'when the user’s namespace has already been trialed' do
      let(:expected_user_options) { [] }

      context 'and the user has no groups or none of their groups can be trialed' do
        it { is_expected.to eq(generated_html) }
      end

      context 'and the user has some groups which can be trialed' do
        let(:expected_group_options) { [group1, group2].map {|g| [g.name, g.id]} }

        it { is_expected.to eq(generated_html) }
      end
    end
  end

  describe '#trial_users' do
    let_it_be(:user) { create :user }
    let(:user_eligible_for_trial_result) { [[user.namespace.name, user.namespace.id]] }
    let(:user_ineligible_for_trial_result) { [] }

    before do
      user.reload # necessary to cache-bust the user.namespace.gitlab_subscription object
      allow(helper).to receive(:current_user).and_return(user)
    end

    subject { helper.trial_users }

    context 'when the user has no subscription on their namespace' do
      it { is_expected.to eq(user_eligible_for_trial_result) }
    end

    context 'when the user has a subscription on their namespace' do
      let(:trialed) { false }
      let!(:subscription) { create :gitlab_subscription, namespace: user.namespace, trial: trialed }

      context 'and the user has not yet trialed their namespace' do
        it { is_expected.to eq(user_eligible_for_trial_result) }
      end

      context 'and the user has already trialed their namespace' do
        let(:trialed) { true }

        it { is_expected.to eq(user_ineligible_for_trial_result) }
      end
    end
  end

  describe '#trial_groups' do
    let_it_be(:user) { create :user }
    let(:no_groups) { [] }

    before do
      allow(helper).to receive(:current_user).and_return(user)
    end

    subject { helper.trial_groups }

    context 'when the user is not an owner/maintainer of any groups' do
      it { is_expected.to eq(no_groups) }
    end

    context 'when the user is an owner/maintainer of some groups' do
      let_it_be(:group1) { create :group, name: 'Group 1' }
      let_it_be(:subgroup1) { create :group, parent: group1, name: 'Sub-Group 1' }
      let_it_be(:group2) { create :group, name: 'Group 2' }
      let_it_be(:subgroup2) { create :group, parent: group2, name: 'Sub-Group 2' }
      let_it_be(:subsubgroup1) { create :group, parent: subgroup2, name: 'Sub-Sub-Group 1' }

      let(:all_groups) { [group1, group2, subgroup1, subgroup2, subsubgroup1].map {|g| [g.name, g.id] } }

      before do
        group1.add_owner(user)
        group2.add_maintainer(user)
      end

      context 'and none of the groups have subscriptions' do
        it { is_expected.to eq(all_groups) }
      end

      context 'and the groups have subscriptions' do
        let(:trialed_group1) { false }
        let(:trialed_subgroup1) { false }
        let(:trialed_group2) { false }
        let(:trialed_subgroup2) { false }
        let(:trialed_subsubgroup1) { false }

        let!(:subscription_group1) { create :gitlab_subscription, namespace: group1, trial: trialed_group1 }
        let!(:subscription_subgroup1) { create :gitlab_subscription, namespace: subgroup1, trial: trialed_subgroup1 }
        let!(:subscription_group2) { create :gitlab_subscription, namespace: group2, trial: trialed_group2 }
        let!(:subscription_subgroup2) { create :gitlab_subscription, namespace: subgroup2, trial: trialed_subgroup2 }
        let!(:subscription_subsubgroup1) { create :gitlab_subscription, namespace: subsubgroup1, trial: trialed_subsubgroup1 }

        context 'and none of the groups have been trialed yet' do
          it { is_expected.to eq(all_groups) }
        end

        context 'and some of the groups have been trialed' do
          let(:trialed_group1) { true }
          let(:trialed_subgroup1) { true }
          let(:trialed_subgroup2) { true }

          let(:some_groups) { [group2, subsubgroup1].map {|g| [g.name, g.id]} }

          it { is_expected.to eq(some_groups) }
        end

        context 'and all of the groups have already been trialed' do
          let(:trialed_group1) { true }
          let(:trialed_subgroup1) { true }
          let(:trialed_group2) { true }
          let(:trialed_subgroup2) { true }
          let(:trialed_subsubgroup1) { true }

          it { is_expected.to eq(no_groups) }
        end
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
