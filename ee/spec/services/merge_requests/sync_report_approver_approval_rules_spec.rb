# frozen_string_literal: true

require 'spec_helper'

describe MergeRequests::SyncReportApproverApprovalRules do
  let(:merge_request) { create(:merge_request) }
  let!(:security_approval_project_rule) { create(:approval_project_rule, :security_report, project: merge_request.target_project, approvals_required: 2) }

  subject(:service) { described_class.new(merge_request) }

  describe '#execute' do
    context 'when report_approver_rules are enabled' do
      let!(:regular_approval_project_rule) { create(:approval_project_rule, project: merge_request.target_project) }

      before do
        stub_feature_flags(report_approver_rules: true)
      end

      it 'creates rule for report approvers' do
        expect { service.execute }
          .to change { merge_request.approval_rules.security_report.count }.from(0).to(1)

        rule = merge_request.approval_rules.security_report.first

        expect(rule).to be_report_approver
        expect(rule.report_type).to eq 'security'
        expect(rule.name).to eq(security_approval_project_rule.name)
        expect(rule.approval_project_rule).to eq(security_approval_project_rule)
      end

      it 'updates previous rules if defined' do
        mr_rule = create(:report_approver_rule, merge_request: merge_request, approvals_required: 0)

        expect { service.execute }
          .not_to change { merge_request.approval_rules.security_report.count }

        expect(mr_rule.reload).to be_report_approver
        expect(mr_rule.report_type).to eq 'security'
        expect(mr_rule.name).to eq(security_approval_project_rule.name)
        expect(mr_rule.approvals_required).to eq security_approval_project_rule.approvals_required
        expect(mr_rule.approval_project_rule).to eq(security_approval_project_rule)
      end
    end

    context 'when report_approver_rules are disabled' do
      before do
        stub_feature_flags(report_approver_rules: false)
      end

      it 'copies nothing' do
        expect { service.execute }
          .not_to change { merge_request.approval_rules.count }
      end
    end
  end
end
