# frozen_string_literal: true

require 'spec_helper'

describe RefreshLicenseComplianceChecksWorker do
  subject { described_class.new }

  describe '#perform' do
    let(:project) { create(:project) }

    before do
      stub_licensed_features(license_management: true)
    end

    context "when there are open merge requests in the project" do
      let!(:merge_request) { create(:merge_request, target_project: project, source_project: project) }

      context "when the `#{ApprovalRuleLike::DEFAULT_NAME_FOR_LICENSE_REPORT}` approval rule is enabled" do
        let!(:merge_request_approval_rule_1) { create(:report_approver_rule, :license_management, merge_request: merge_request) }
        let!(:project_approval_rule_1) { create(:approval_project_rule, :requires_approval, :license_management, project: project) }

        context "when a license is blacklisted, that appears in some of the license management reports" do
          let!(:pipeline) { create(:ee_ci_pipeline, :success, :with_license_management_report, project: project, merge_requests_as_head_pipeline: [merge_request]) }
          let!(:blacklist_policy) { create(:software_license_policy, project: project, software_license: license, approval_status: :blacklisted) }
          let(:license) { create(:software_license, name: license_report.license_names[0]) }
          let(:license_report) { pipeline.license_management_report }

          before do
            subject.perform(project.id)
          end

          specify { expect(merge_request.approval_rules.license_management.first.approvals_required).to eql(project_approval_rule_1.approvals_required) }
        end
      end
    end
  end
end
