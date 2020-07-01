# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EE::TrialHelper do
  using RSpec::Parameterized::TableSyntax

  describe '#namespace_options_for_select' do
    let_it_be(:user) { create :user }

    let(:expected_prompt_option) { 'Please select' }
    let(:expected_new_options) { [['Create group', 0]] }
    let(:expected_group_options) { [] }
    let(:expected_user_options) { [[user.namespace.name, user.namespace.id]] }
    let(:generated_html) do
      grouped_options_for_select({
        'New' => expected_new_options,
        'Groups' => expected_group_options,
        'Users' => expected_user_options
      }, nil, prompt: expected_prompt_option)
    end

    before do
      user.reload # necessary to cache-bust the user.namespace.gitlab_subscription object
      allow(helper).to receive(:current_user).and_return(user)
    end

    subject { helper.namespace_options_for_select }

    context 'when a user owns no groups beyond their personal namespace' do
      it 'shows “Create group” & user namespace options' do
        expect(subject).to eq(generated_html)
      end

      context 'when they have already trialed their personal namespace' do
        before do
          create :gitlab_subscription, namespace: user.namespace, trial: true
        end

        let(:expected_user_options) { [] }

        it 'only shows “Create group” option' do
          expect(subject).to eq(generated_html)
        end
      end
    end

    context 'when a user is an owner of a group beyond their personal namespace' do
      let_it_be(:group) { create :group }

      before do
        group.add_owner(user)
      end

      context 'when the group is eligible for a trial' do
        let(:expected_group_options) { [[group.name, group.id]] }

        it 'shows options for “Create group,” for the group namespace, & for their user namespace' do
          expect(subject).to eq(generated_html)
        end
      end

      context 'when they have already trialed the group' do
        before do
          create :gitlab_subscription, namespace: group, trial: true
        end

        it 'shows options for “Create group” & their user namespace, but not for the group' do
          expect(subject).to eq(generated_html)
        end
      end

      context 'when they have already trialed their personal namespace' do
        before do
          create :gitlab_subscription, namespace: user.namespace, trial: true
        end

        let(:expected_group_options) { [[group.name, group.id]] }
        let(:expected_user_options) { [] }

        it 'shows options for “Create group” & the group namespace, but not their user namespace' do
          expect(subject).to eq(generated_html)
        end
      end

      context 'when they have already trialed the group & their personal namespace' do
        before do
          create :gitlab_subscription, namespace: user.namespace, trial: true
          create :gitlab_subscription, namespace: group, trial: true
        end

        let(:expected_user_options) { [] }

        it 'only shows the “Create group” option' do
          expect(subject).to eq(generated_html)
        end
      end
    end

    context 'when a user is an owner or maintainer of several namespaces' do
      let_it_be(:group1) { create :group, name: 'Group 1' }
      let_it_be(:subgroup) { create :group, parent: group1, name: 'Sub-Group 1' }
      let_it_be(:group2) { create :group, name: 'Group 2' }
      let_it_be(:subgroup2) { create :group, parent: group2, name: 'Sub-Group 2' }
      let_it_be(:subsubgroup) { create :group, parent: subgroup2, name: 'Sub-Sub-Group 1' }

      before do
        group1.add_owner(user)
        group2.add_maintainer(user)
      end

      context 'when each namespace is eligible for a trial' do
        let(:expected_group_options) do
          [
            [group1.name, group1.id],
            [group2.name, group2.id],
            [subgroup.name, subgroup.id],
            [subgroup2.name, subgroup2.id],
            [subsubgroup.name, subsubgroup.id]
          ]
        end

        it 'shows options for “Create group,” for each group namespace, & for their user namespace' do
          expect(subject).to eq(generated_html)
        end
      end

      context 'when they have already trialed for their user & some of the groups' do
        before do
          create :gitlab_subscription, namespace: user.namespace, trial: true
          create :gitlab_subscription, namespace: group1, trial: true
          create :gitlab_subscription, namespace: group2, trial: true
          create :gitlab_subscription, namespace: subgroup, trial: true
        end

        let(:expected_group_options) do
          [
            [subgroup2.name, subgroup2.id],
            [subsubgroup.name, subsubgroup.id]
          ]
        end
        let(:expected_user_options) { [] }

        it 'only shows options for “Create group” & for the non-trialed groups' do
          expect(subject).to eq(generated_html)
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
