# frozen_string_literal: true

require 'spec_helper'

describe ApprovalRules::CopyToMergeRequestService do
  let(:approver1) { create(:user) }
  let(:approver2) { create(:user) }

  let(:project) do
    create(:project).tap do |project|
      create(:approval_project_rule, project: project, users: [approver1])
      create(:approval_project_rule, project: project, users: [approver2])
    end
  end
  let(:merge_request) { create(:merge_request, target_project: project, source_project: project) }
  let(:user) { project.creator }

  describe '#execute' do
    it 'copies project rules as merge request rules' do
      described_class.new(merge_request, user).execute

      rules = merge_request.approval_rules.regular

      project.approval_rules.each do |project_rule|
        rule = rules.find { |rule| rule.approval_project_rule == project_rule}

        [:name, :users, :groups, :approvals_required].each do |attr|
          expect(rule.read_attribute(attr)).to eq(project_rule.read_attribute(attr))
        end
        expect(rule.rule_type).to eq('regular')
      end
    end

    it 'does nothing if merge request rule already exists' do
      merge_request_rule = create(:approval_merge_request_rule, merge_request: merge_request, users: [approver1])

      described_class.new(merge_request, user).execute

      expect(merge_request.approval_rules.regular).to contain_exactly(merge_request_rule)
    end
  end
end
