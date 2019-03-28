# frozen_string_literal: true

require 'spec_helper'

describe ApprovalRules::UpdateService do
  let(:project) { create(:project) }
  let(:user) { project.creator }

  shared_examples 'editable' do
    let(:approval_rule) { target.approval_rules.create(name: 'foo') }
    let(:new_approvers) { create_list(:user, 2) }
    let(:new_groups) { create_list(:group, 2, :private) }

    it 'updates approval, excluding non-eligible users and groups' do
      result = described_class.new(approval_rule, user, {
        name: 'security',
        approvals_required: 1,
        user_ids: new_approvers.map(&:id),
        group_ids: new_groups.map(&:id)
      }).execute

      expect(result[:status]).to eq(:success)

      rule = result[:rule]

      expect(rule.name).to eq('security')
      expect(rule.approvals_required).to eq(1)
      expect(rule.users).to be_empty
      expect(rule.groups).to be_empty
    end

    context 'when some users and groups are eligible' do
      before do
        project.add_reporter new_approvers.first
        new_groups.first.add_guest user
      end

      it 'creates and includes eligible users and groups' do
        result = described_class.new(approval_rule, user, {
          name: 'security',
          approvals_required: 1,
          user_ids: new_approvers.map(&:id),
          group_ids: new_groups.map(&:id)
        }).execute

        expect(result[:status]).to eq(:success)

        rule = result[:rule]

        expect(rule.name).to eq('security')
        expect(rule.approvals_required).to eq(1)
        expect(rule.users).to contain_exactly(new_approvers.first)
        expect(rule.groups).to contain_exactly(new_groups.first)
      end
    end

    context 'when existing groups are inaccessible to user' do
      let(:private_accessible_group) { create(:group, :private) }
      let(:private_inaccessible_group) { create(:group, :private) }
      let(:new_group) { create(:group) }

      before do
        approval_rule.groups = [private_accessible_group, private_inaccessible_group]
        private_accessible_group.add_guest user
      end

      context 'when remove_hidden_groups is false' do
        it 'preserves inaccessible groups' do
          result = described_class.new(approval_rule, user, {
            remove_hidden_groups: false,
            group_ids: [new_group.id]
          }).execute

          expect(result[:status]).to eq(:success)

          rule = result[:rule]

          expect(rule.groups).to contain_exactly(private_inaccessible_group, new_group)
        end
      end

      context 'when remove_hidden_groups is not specified' do
        it 'removes inaccessible groups' do
          result = described_class.new(approval_rule, user, {
            group_ids: [new_group.id]
          }).execute

          expect(result[:status]).to eq(:success)

          rule = result[:rule]

          expect(rule.groups).to contain_exactly(private_inaccessible_group, new_group)
        end
      end

      context 'when remove_hidden_groups is true' do
        it 'removes inaccessible groups' do
          result = described_class.new(approval_rule, user, {
            remove_hidden_groups: true,
            group_ids: [new_group.id]
          }).execute

          expect(result[:status]).to eq(:success)

          rule = result[:rule]

          expect(rule.groups).to contain_exactly(new_group)
        end
      end
    end

    context 'when validation fails' do
      it 'returns error message' do
        result = described_class.new(approval_rule, user, {
          name: nil,
          approvals_required: 1
        }).execute

        expect(result[:status]).to eq(:error)
      end
    end

    context 'when user does not have right to edit' do
      let(:user) { create(:user) }

      it 'returns error message' do
        result = described_class.new(approval_rule, user, {
          approvals_required: 1
        }).execute

        expect(result[:status]).to eq(:error)
        expect(result[:message]).to include('Prohibited')
      end
    end
  end

  context 'when target is project' do
    let(:target) { project }

    it_behaves_like "editable"
  end

  context 'when target is merge request' do
    let(:target) { create(:merge_request, source_project: project, target_project: project) }

    it_behaves_like "editable"
  end
end
