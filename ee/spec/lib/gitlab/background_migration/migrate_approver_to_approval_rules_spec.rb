# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::BackgroundMigration::MigrateApproverToApprovalRules do
  def create_skip_sync(*args)
    build(*args) do |record|
      allow(record).to receive(:schedule_approval_migration)
      record.save!
    end
  end

  def create_member_in(member, *populate_in)
    if populate_in.include?(:old_schema)
      case member
      when User
        create_skip_sync(:approver, target_type: target_type, target_id: target.id, user_id: member.id)
      when Group
        create_skip_sync(:approver_group, target_type: target_type, target_id: target.id, group_id: member.id)
      end
    end

    if populate_in.include?(:new_schema)
      approval_rule.add_member(member)
    end
  end

  context 'sync approval rule and its members' do
    shared_examples 'sync approval member' do
      let(:user1) { create(:user) }
      let(:user2) { create(:user) }
      let(:group1) { create(:group) }
      let(:group2) { create(:group) }

      context 'when member in old schema but not in new schema' do
        before do
          create_member_in(user1, :old_schema)
          create_member_in(group1, :old_schema)
        end

        it 'creates in new schema' do
          expect do
            described_class.new.perform(target_type, target.id)
          end.to change { approval_rule.users.count }.by(1)
            .and change { approval_rule.groups.count }.by(1)

          approval_rule = target.approval_rules.first

          expect(approval_rule.approvals_required).to eq(0)
          expect(approval_rule.name).to eq('Default')

          expect(approval_rule.users).to contain_exactly(user1)
          expect(approval_rule.groups).to contain_exactly(group1)
        end
      end

      context 'when member not in old schema but in new schema' do
        before do
          create_member_in(user1, :new_schema)
          create_member_in(user2, :old_schema, :new_schema)
          create_member_in(group1, :new_schema)
          create_member_in(group2, :old_schema, :new_schema)
        end

        it 'removes in new schema' do
          expect do
            described_class.new.perform(target_type, target.id)
          end.to change { approval_rule.users.count }.by(-1)
            .and change { approval_rule.groups.count }.by(-1)

          approval_rule = target.approval_rules.first

          expect(approval_rule.users).to contain_exactly(user2)
          expect(approval_rule.groups).to contain_exactly(group2)
        end
      end
    end

    context 'merge request' do
      let(:target) { create(:merge_request) }
      let(:target_type) { 'MergeRequest' }
      let(:approval_rule) { create(:approval_merge_request_rule, merge_request: target) }

      it_behaves_like 'sync approval member'

      context 'when approver is no longer overwritten' do
        before do
          create_member_in(create(:user), :new_schema)
          create_member_in(create(:group), :new_schema)
        end

        it 'removes rule' do
          expect do
            described_class.new.perform(target_type, target.id)
          end.to change { approval_rule.users.count }.by(-1)
            .and change { approval_rule.groups.count }.by(-1)

          expect(target.approval_rules.exists?(approval_rule.id)).to eq(false)
        end
      end
    end

    context 'project' do
      let(:target) { create(:project) }
      let(:target_type) { 'Project' }
      let(:approval_rule) { create(:approval_project_rule, project: target) }

      it_behaves_like 'sync approval member'

      context 'when project contains some merge requests' do
        let!(:merge_request) { create(:merge_request, source_project: target, target_project: target) }

        it 'schedules migrations for all its merge requests' do
          expect(BackgroundMigrationWorker).to receive(:bulk_perform_async).with([['MigrateApproverToApprovalRulesInBatch', ["MergeRequest", [merge_request.id]]]])

          described_class.new.perform(target.class.name, target.id)
        end
      end
    end
  end

  # Copied and modified from merge_request_spec.rb
  describe '#finalize_approvals' do
    let(:project) { create(:project, :repository) }
    subject(:merge_request) { create(:merge_request, source_project: project, target_project: project) }
    let(:target) { merge_request }

    let!(:member1) { create(:user) }
    let!(:member2) { create(:user) }
    let!(:member3) { create(:user) }
    let!(:group1) { create(:group) }
    let!(:group2) { create(:group) }
    let!(:group1_member) { create(:user) }
    let!(:group2_member) { create(:user) }
    let!(:approval1) { create(:approval, merge_request: subject, user: member1) }
    let!(:approval2) { create(:approval, merge_request: subject, user: member3) }
    let!(:approval3) { create(:approval, merge_request: subject, user: group1_member) }
    let!(:approval4) { create(:approval, merge_request: subject, user: group2_member) }

    before do
      group1.add_guest(group1_member)
      group2.add_guest(group2_member)

      rule = create(:approval_project_rule, project: project, name: 'foo', approvals_required: 12)

      rule.users = [member1, member2]
      rule.groups << group1
    end

    context 'when without MR rules (project rule not overwritten)' do
      it 'does nothing if unmerged' do
        expect do
          described_class.new.perform(target.class.name, target.id)
        end.not_to change { ApprovalMergeRequestRule.count }

        expect(approval1.approval_rules).to be_empty
        expect(approval2.approval_rules).to be_empty
        expect(approval3.approval_rules).to be_empty
        expect(approval4.approval_rules).to be_empty
      end

      context 'when merged' do
        subject(:merge_request) { create(:merged_merge_request, source_project: project, target_project: project) }

        it 'copies project rules to MR' do
          expect do
            described_class.new.perform(target.class.name, target.id)
          end.to change { ApprovalMergeRequestRule.count }.by(1)

          rule = subject.approval_rules.first

          expect(rule.name).to eq('foo')
          expect(rule.approvals_required).to eq(12)

          expect(rule.users).to contain_exactly(member1, member2)
          expect(rule.groups).to contain_exactly(group1)

          rule = subject.approval_rules.first

          expect(approval1.approval_rules).to contain_exactly(rule)
          expect(approval2.approval_rules).to be_empty
          expect(approval3.approval_rules).to contain_exactly(rule)
          expect(approval4.approval_rules).to be_empty
        end
      end
    end

    context 'when with MR approver exists (project rule overwritten)' do
      before do
        create_skip_sync(:approver, target: subject, user: member2)
        create_skip_sync(:approver, target: subject, user: member3)
        create_skip_sync(:approver_group, target: subject, group: group2)

        merge_request.update(approvals_before_merge: 32)
      end

      it 'does not call finalize_approvals if unmerged' do
        expect do
          described_class.new.perform(target.class.name, target.id)
        end.to change { ApprovalMergeRequestRule.count }.by(1)

        expect(approval1.approval_rules).to be_empty
        expect(approval2.approval_rules).to be_empty
        expect(approval3.approval_rules).to be_empty
        expect(approval4.approval_rules).to be_empty
      end

      context 'when merged' do
        subject(:merge_request) { create(:merged_merge_request, source_project: project, target_project: project) }

        it 'does not copy project rules, and updates approval mapping with MR rules' do
          expect(subject).not_to receive(:copy_project_approval_rules)

          expect do
            described_class.new.perform(target.class.name, target.id)
          end.to change { ApprovalMergeRequestRule.count }.by(1)

          rule = subject.approval_rules.first

          expect(rule.name).to eq('Default')
          expect(rule.approvals_required).to eq(32)

          expect(rule.users).to contain_exactly(member2, member3)
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
