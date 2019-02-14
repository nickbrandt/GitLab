# frozen_string_literal: true

require 'spec_helper'

describe ApprovalRulePresenter do
  describe '#groups' do
    set(:user) { create(:user) }
    set(:public_group) { create(:group) }
    set(:private_group) { create(:group, :private) }
    let(:groups) { [public_group, private_group] }
    subject { described_class.new(rule, current_user: user) }

    shared_examples 'filtering private group' do
      context 'when user has no access to private group' do
        it 'excludes private group' do
          expect(subject.groups).to contain_exactly(public_group)
        end
      end

      context 'when user has access to private group' do
        it 'includes private group' do
          private_group.add_owner(user)

          expect(subject.groups).to contain_exactly(*groups)
        end
      end
    end

    context 'project rule' do
      let(:rule) { create(:approval_project_rule, groups: groups) }

      it_behaves_like 'filtering private group'
    end

    context 'wrapped approval rule' do
      let(:rule) do
        mr_rule = create(:approval_merge_request_rule, groups: groups)
        ApprovalWrappedRule.new(mr_rule.merge_request, mr_rule)
      end

      it_behaves_like 'filtering private group'
    end

    context 'fallback rule' do
      let(:rule) { ApprovalMergeRequestFallback.new(create(:merge_request)) }

      it 'contains no groups without raising an error' do
        expect(subject.groups).to be_empty
      end
    end
  end
end
