# frozen_string_literal: true
require 'spec_helper'

describe ApprovalMergeRequestFallback do
  using RSpec::Parameterized::TableSyntax

  let(:merge_request) { create(:merge_request, approvals_before_merge: 2) }
  let(:project) { merge_request.project }
  subject(:rule) { described_class.new(merge_request) }

  describe '#approvals_required' do
    where(:merge_request_requirement, :project_requirement, :project_rule_requirement, :expected) do
      nil | nil | nil | 0
      10  | 5   | nil | 10
      2   | 9   | nil | 9
      2   | 9   | 7   | 7
      10  | 9   | 7   | 10
    end

    with_them do
      before do
        merge_request.approvals_before_merge = merge_request_requirement
        project.approvals_before_merge = project_requirement
        if project_rule_requirement
          create(:approval_project_rule,
                 project: project,
                 approvals_required: project_rule_requirement)
        end
      end

      it 'returns the expected value' do
        expect(rule.approvals_required).to eq(expected)
      end
    end
  end

  describe '#approvals_left' do
    it 'returns the correct number of approvals left' do
      create(:approval, merge_request: merge_request)

      expect(rule.approvals_left).to eq(1)
    end
  end

  describe '#approved?' do
    it 'is falsy' do
      expect(rule.approved?).to be(false)
    end

    it 'is true if there where enough approvals' do
      create_list(:approval, 2, merge_request: merge_request)

      expect(rule.approved?).to be(true)
    end
  end
end
