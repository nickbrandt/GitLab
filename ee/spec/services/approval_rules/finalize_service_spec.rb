# frozen_string_literal: true

require 'spec_helper'

describe ApprovalRules::FinalizeService do
  let(:project) { create(:project, :repository) }
  let(:merge_request) { create(:merge_request, source_project: project, target_project: project) }

  describe '#execute' do
    let!(:member1) { create(:user) }
    let!(:member2) { create(:user) }
    let!(:member3) { create(:user) }
    let!(:group1) { create(:group) }
    let!(:group2) { create(:group) }
    let!(:group1_member) { create(:user) }
    let!(:group2_member) { create(:user) }
    let!(:approval1) { create(:approval, merge_request: merge_request, user: member1) }
    let!(:approval2) { create(:approval, merge_request: merge_request, user: member3) }
    let!(:approval3) { create(:approval, merge_request: merge_request, user: group1_member) }
    let!(:approval4) { create(:approval, merge_request: merge_request, user: group2_member) }
    let!(:project_rule) { create(:approval_project_rule, project: project, name: 'foo', approvals_required: 12) }

    subject { described_class.new(merge_request) }

    before do
      group1.add_guest(group1_member)
      group2.add_guest(group2_member)

      project_rule.users = [member1, member2]
      project_rule.groups << group1
    end

    shared_examples 'skipping when unmerged' do
      it 'does nothing if unmerged' do
        expect do
          subject.execute
        end.not_to change { ApprovalMergeRequestRule.count }

        expect(approval1.approval_rules).to be_empty
        expect(approval2.approval_rules).to be_empty
        expect(approval3.approval_rules).to be_empty
        expect(approval4.approval_rules).to be_empty
      end
    end

    context 'when project rule is not overwritten' do
      it_behaves_like 'skipping when unmerged'

      context 'when merged' do
        let(:merge_request) { create(:merged_merge_request, source_project: project, target_project: project) }

        before do
          merge_request.approval_rules.code_owner.create(name: 'Code Owner')
        end

        it 'copies project rules to MR, keep snapshot of group member by including it as part of users association' do
          expect do
            subject.execute
          end.to change { ApprovalMergeRequestRule.count }.by(1)

          rule = merge_request.approval_rules.regular.first

          expect(rule.name).to eq('foo')
          expect(rule.approvals_required).to eq(12)
          expect(rule.users).to contain_exactly(member1, member2, group1_member)
          expect(rule.groups).to contain_exactly(group1)
          expect(approval1.approval_rules).to contain_exactly(rule)
          expect(approval2.approval_rules).to be_empty
          expect(approval3.approval_rules).to contain_exactly(rule)
          expect(approval4.approval_rules).to be_empty
        end
      end
    end

    context 'when project rule is overwritten' do
      before do
        rule = create(:approval_merge_request_rule, merge_request: merge_request, name: 'bar', approvals_required: 32)
        rule.users = [member2, member3]
        rule.groups << group2
      end

      it_behaves_like 'skipping when unmerged'

      context 'when merged' do
        let(:merge_request) { create(:merged_merge_request, source_project: project, target_project: project) }

        it 'does not copy project rules, and updates approval mapping with MR rules' do
          expect(merge_request).not_to receive(:copy_project_approval_rules)

          expect do
            subject.execute
          end.not_to change { ApprovalMergeRequestRule.count }

          rule = merge_request.approval_rules.regular.first

          expect(rule.name).to eq('bar')
          expect(rule.approvals_required).to eq(32)
          expect(rule.users).to contain_exactly(member2, member3, group2_member)
          expect(rule.groups).to contain_exactly(group2)
          expect(approval1.approval_rules).to be_empty
          expect(approval2.approval_rules).to contain_exactly(rule)
          expect(approval3.approval_rules).to be_empty
          expect(approval4.approval_rules).to contain_exactly(rule)
        end
      end
    end
  end
end
