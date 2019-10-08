# frozen_string_literal: true

require 'spec_helper'

describe ApprovalWrappedRule do
  using RSpec::Parameterized::TableSyntax

  let(:merge_request) { create(:merge_request) }
  let(:rule) { create(:approval_merge_request_rule, merge_request: merge_request, approvals_required: approvals_required) }
  let(:approvals_required) { 0 }
  let(:approver1) { create(:user) }
  let(:approver2) { create(:user) }
  let(:approver3) { create(:user) }

  subject { described_class.new(merge_request, rule) }

  describe '#project' do
    it 'returns merge request project' do
      expect(subject.project).to eq(merge_request.target_project)
    end
  end

  describe '#approvals_left' do
    before do
      create(:approval, merge_request: merge_request, user: approver1)
      create(:approval, merge_request: merge_request, user: approver2)
      rule.users << approver1
      rule.users << approver2
    end

    context 'when approvals_required is greater than approved approver count' do
      let(:approvals_required) { 8 }

      it 'returns approvals still needed' do
        expect(subject.approvals_left).to eq(6)
      end
    end

    context 'when approvals_required is less than approved approver count' do
      let(:approvals_required) { 1 }

      it 'returns zero' do
        expect(subject.approvals_left).to eq(0)
      end
    end
  end

  describe '#approved?' do
    before do
      create(:approval, merge_request: merge_request, user: approver1)
      rule.users << approver1
    end

    context 'when approvals left is zero' do
      let(:approvals_required) { 1 }

      it 'returns true' do
        expect(subject.approved?).to eq(true)
      end
    end

    context 'when approvals left is not zero, but there is still unactioned approvers' do
      let(:approvals_required) { 99 }

      before do
        rule.users << approver2
      end

      it 'returns false' do
        expect(subject.approved?).to eq(false)
      end
    end

    context 'when approvals left is not zero, but there is no unactioned approvers' do
      let(:approvals_required) { 99 }

      it 'returns true' do
        expect(subject.approved?).to eq(true)
      end
    end
  end

  describe '#approved_approvers' do
    context 'when some approvers has made the approvals' do
      before do
        create(:approval, merge_request: merge_request, user: approver1)
        create(:approval, merge_request: merge_request, user: approver2)

        rule.users = [approver1, approver3]
      end

      it 'returns approved approvers' do
        expect(subject.approved_approvers).to contain_exactly(approver1)
      end
    end

    context 'when merged' do
      let(:merge_request) { create(:merged_merge_request) }

      before do
        rule.approved_approvers << approver3
      end

      it 'returns approved approvers from database' do
        expect(subject.approved_approvers).to contain_exactly(approver3)
      end
    end

    context 'when merged but without materialized approved_approvers' do
      let(:merge_request) { create(:merged_merge_request) }

      before do
        create(:approval, merge_request: merge_request, user: approver1)
        create(:approval, merge_request: merge_request, user: approver2)

        rule.users = [approver1, approver3]
      end

      it 'returns computed approved approvers' do
        expect(subject.approved_approvers).to contain_exactly(approver1)
      end
    end

    context 'when project rule' do
      let(:rule) { create(:approval_project_rule, project: merge_request.project, approvals_required: approvals_required) }
      let(:merge_request) { create(:merged_merge_request) }

      before do
        create(:approval, merge_request: merge_request, user: approver1)
        create(:approval, merge_request: merge_request, user: approver2)

        rule.users = [approver1, approver3]
      end

      it 'returns computed approved approvers' do
        expect(subject.approved_approvers).to contain_exactly(approver1)
      end
    end
  end

  describe '#unactioned_approvers' do
    context 'when some approvers has not approved yet' do
      before do
        create(:approval, merge_request: merge_request, user: approver1)
        rule.users = [approver1, approver2]
      end

      it 'returns unactioned approvers' do
        expect(subject.unactioned_approvers).to contain_exactly(approver2)
      end
    end

    context 'when merged' do
      let(:merge_request) { create(:merged_merge_request) }

      before do
        rule.approved_approvers << approver3
        rule.users = [approver1, approver3]
      end

      it 'returns approved approvers from database' do
        expect(subject.unactioned_approvers).to contain_exactly(approver1)
      end
    end
  end

  describe '#approvals_required' do
    context 'for regular rules' do
      let(:rule) { create(:approval_merge_request_rule, approvals_required: 19) }

      it 'returns the attribute saved on the model' do
        expect(subject.approvals_required).to eq(19)
      end
    end

    context 'for code owner rules' do
      where(:feature_enabled, :approver_count, :expected_required_approvals) do
        true  | 0 | 0
        true  | 2 | 1
        false | 2 | 0
        false | 0 | 0
      end

      with_them do
        let(:rule) do
          create(:code_owner_rule,
                 merge_request: merge_request,
                 users: create_list(:user, approver_count))
        end

        let(:branch) { subject.project.repository.branches.find { |b| b.name == merge_request.target_branch } }

        context "when project.code_owner_approval_required_available? is true" do
          before do
            allow(subject.project)
              .to receive(:code_owner_approval_required_available?).and_return(true)
          end

          context "when the project doesn't require code owner approval on all MRs" do
            it 'returns the expected number of approvals for protected_branches that do require approval' do
              allow(subject.project)
                .to receive(:merge_requests_require_code_owner_approval?).and_return(false)
              allow(ProtectedBranch)
                .to receive(:branch_requires_code_owner_approval?).with(subject.project, branch.name).and_return(feature_enabled)

              expect(subject.approvals_required).to eq(expected_required_approvals)
            end
          end
        end

        context "when project.code_owner_approval_required_available? is falsy" do
          it "returns nil" do
            allow(subject.project)
              .to receive(:code_owner_approval_required_available?).and_return(false)

            expect(subject.approvals_required).to eq(0)
          end
        end
      end
    end
  end
end
