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

    ApprovalProjectRule::REPORT_TYPES_BY_DEFAULT_NAME.keys.each do |rule_name|
      context "when the rule name is `#{rule_name}`" do
        subject { described_class.new(target, user, { name: rule_name, approvals_required: 1 }) }

        let(:result) { subject.execute }

        specify { expect(result[:status]).to eq(:success) }
        specify { expect(result[:rule].approvals_required).to eq(1) }
        specify { expect(result[:rule].rule_type).to eq('report_approver') }
      end
    end

    context 'when approval rule is being created' do
      subject { described_class.new(target, user, { user_ids: [], group_ids: [] }) }

      it 'sets default attributes for any-approver rule' do
        rule = subject.execute[:rule]

        expect(rule[:rule_type]).to eq('any_approver')
        expect(rule[:name]).to eq('All Members')
      end
    end

    context 'when any-approver rule exists' do
      let!(:any_approver_rule) do
        create(:approval_project_rule, project: target, rule_type: :any_approver)
      end

      context 'multiple approval rules are not enabled' do
        subject { described_class.new(target, user, { user_ids: [1], group_ids: [] }) }

        before do
          stub_licensed_features(multiple_approval_rules: false)
        end

        it 'removes the rule if a regular one is created' do
          expect { subject.execute }.to change(
            target.approval_rules.any_approver, :count
          ).from(1).to(0)
        end
      end
    end
  end

  context 'when target is merge request' do
    let(:target) { create(:merge_request, source_project: project, target_project: project) }

    it_behaves_like "creatable"

    context 'when project rule id is present' do
      let(:project_rule) do
        create(
          :approval_project_rule,
          project: project,
          name: 'bar',
          approvals_required: 1,
          users: [create(:user)],
          groups: [create(:group)]
        )
      end

      let(:result) do
        described_class.new(target, user, {
          name: 'foo',
          approvals_required: 0,
          approval_project_rule_id: project_rule.id,
          user_ids: [],
          group_ids: []
        }).execute
      end

      let(:rule) { result[:rule] }

      it 'associates with project rule' do
        expect(result[:status]).to eq(:success)
        expect(rule.approvals_required).to eq(0)
        expect(rule.approval_project_rule).to eq(project_rule)
      end

      it 'copies properties from the project rule' do
        expect(rule.name).to eq(project_rule.name)
        expect(rule.users).to match(project_rule.users)
        expect(rule.groups).to match(project_rule.groups)
      end

      context 'when project rule is under the same project as MR' do
        let(:another_project) { create(:project) }

        before do
          project_rule.update!(project: another_project)
        end

        it 'ignores assignment' do
          expect(result[:status]).to eq(:success)
          expect(rule.approvals_required).to eq(0)
          expect(rule.approval_project_rule).to eq(nil)
        end

        it 'does not copy properties from project rule' do
          expect(rule.name).to eq('foo')
          expect(rule.users).to be_empty
          expect(rule.groups).to be_empty
        end
      end
    end
  end
end
