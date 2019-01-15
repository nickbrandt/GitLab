# frozen_string_literal: true

require 'spec_helper'

describe ApprovalRules::CreateService do
  let(:project) { create(:project) }
  let(:user) { project.creator }

  shared_examples 'creatable' do
    let(:new_approvers) { create_list(:user, 2) }
    let(:new_groups) { create_list(:group, 2, :private) }

    it 'creates approval, excluding non-eligible users and groups' do
      result = described_class.new(target, user, {
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
        new_groups.first.add_guest(user)
      end

      it 'creates and includes eligible users and groups' do
        result = described_class.new(target, user, {
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

    context 'when validation fails' do
      it 'returns error message' do
        result = described_class.new(target, user, {
          name: nil,
          approvals_required: 1
        }).execute

        expect(result[:status]).to eq(:error)
      end
    end

    context 'when user does not have right to admin project' do
      let(:user) { create(:user) }

      it 'returns error message' do
        result = described_class.new(target, user, {
          approvals_required: 1
        }).execute

        expect(result[:status]).to eq(:error)
        expect(result[:message]).to include('Prohibited')
      end
    end
  end

  context 'when target is project' do
    let(:target) { project }

    it_behaves_like "creatable"
  end

  context 'when target is merge request' do
    let(:target) { create(:merge_request, source_project: project, target_project: project) }

    it_behaves_like "creatable"
  end
end
