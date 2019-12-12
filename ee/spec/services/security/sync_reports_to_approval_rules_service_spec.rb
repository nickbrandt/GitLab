# frozen_string_literal: true

require 'spec_helper'

describe Security::SyncReportsToApprovalRulesService, '#execute' do
  let(:merge_request) { create(:merge_request) }
  let(:project) { merge_request.project }
  let(:pipeline) { create(:ee_ci_pipeline, :success, project: project, merge_requests_as_head_pipeline: [merge_request]) }
  let(:report_approver_rule) { create(:report_approver_rule, merge_request: merge_request, approvals_required: 2) }

  subject { described_class.new(pipeline).execute }

  before do
    allow(Ci::Pipeline).to receive(:find).with(pipeline.id) { pipeline }

    stub_licensed_features(dependency_scanning: true, dast: true, license_management: true)
  end

  context 'when there are reports' do
    context 'when pipeline passes' do
      context 'when high-severity vulnerabilities are present' do
        before do
          create(:ee_ci_build, :success, :dependency_scanning, name: 'ds_job', pipeline: pipeline, project: project)
        end

        it "won't change approvals_required count" do
          expect(
            pipeline.security_reports.reports.values.all?(&:unsafe_severity?)
          ).to be true

          expect { subject }
            .not_to change { report_approver_rule.reload.approvals_required }
        end
      end

      context 'when only low-severity vulnerabilities are present' do
        before do
          create(:ee_ci_build, :success, :low_severity_dast_report, name: 'dast_job', pipeline: pipeline, project: project)
        end

        it 'lowers approvals_required count to zero' do
          expect(
            pipeline.security_reports.reports.values.none?(&:unsafe_severity?)
          ).to be true

          expect { subject }
            .to change { report_approver_rule.reload.approvals_required }.from(2).to(0)
        end
      end

      context 'when merge_requests are merged' do
        let!(:merge_request) { create(:merge_request, :merged) }

        before do
          create(:ee_ci_build, :success, :dast, name: 'dast_job', pipeline: pipeline, project: project)
        end

        it "won't change approvals_required count" do
          expect { subject }
            .not_to change { report_approver_rule.reload.approvals_required }
        end
      end

      context "license compliance policy" do
        let!(:software_license_policy) { create(:software_license_policy, :denied, project: project, software_license: denied_license) }
        let!(:license_compliance_rule) { create(:report_approver_rule, :license_management, merge_request: merge_request, approvals_required: 1) }
        let!(:denied_license) { create(:software_license) }

        context "when a license violates the license compliance policy" do
          let!(:denied_license) { create(:software_license, name: license_name) }
          let!(:ci_build) { create(:ee_ci_build, :success, :license_management, pipeline: pipeline, project: project) }
          let!(:license_name) { ci_build.pipeline.license_scanning_report.license_names[0] }

          specify { expect { subject }.not_to change { license_compliance_rule.reload.approvals_required } }
          specify { expect(subject[:status]).to be(:success) }
        end

        context "when no licenses violate the license compliance policy" do
          let!(:ci_build) { create(:ee_ci_build, :success, :license_management, pipeline: pipeline, project: project) }

          specify { expect { subject }.to change { license_compliance_rule.reload.approvals_required }.from(1).to(0) }
          specify { expect(subject[:status]).to be(:success) }
        end

        context "when an unexpected error occurs" do
          before do
            allow_any_instance_of(Gitlab::Ci::Reports::LicenseScanning::Report).to receive(:violates?).and_raise('heck')
          end

          specify { expect(subject[:status]).to be(:error) }
          specify { expect(subject[:message]).to eql("Failed to update approval rules") }
        end
      end
    end

    context 'when pipeline fails' do
      before do
        pipeline.update!(status: :failed)
      end

      context 'when high-severity vulnerabilities are present' do
        before do
          create(:ee_ci_build, :success, :dependency_scanning, name: 'ds_job', pipeline: pipeline, project: project)
        end

        it "won't change approvals_required count" do
          expect(
            pipeline.security_reports.reports.values.all?(&:unsafe_severity?)
          ).to be true

          expect { subject }
            .not_to change { report_approver_rule.reload.approvals_required }
        end
      end

      context 'when only low-severity vulnerabilities are present' do
        before do
          create(:ee_ci_build, :success, :low_severity_dast_report, name: 'dast_job', pipeline: pipeline, project: project)
        end

        it 'lowers approvals_required count to zero' do
          expect(
            pipeline.security_reports.reports.values.none?(&:unsafe_severity?)
          ).to be true

          expect { subject }
            .to change { report_approver_rule.reload.approvals_required }
        end
      end
    end
  end

  context 'without reports' do
    let(:pipeline) { create(:ci_pipeline, :running, project: project, merge_requests_as_head_pipeline: [merge_request]) }

    it "won't change approvals_required count" do
      expect { subject }
        .not_to change { report_approver_rule.reload.approvals_required }
    end

    context "license compliance policy" do
      let!(:software_license_policy) { create(:software_license_policy, :denied, project: project, software_license: denied_license) }
      let!(:license_compliance_rule) { create(:report_approver_rule, :license_management, merge_request: merge_request, approvals_required: 1) }
      let!(:denied_license) { create(:software_license) }

      specify { expect { subject }.not_to change { license_compliance_rule.reload.approvals_required } }
      specify { expect(subject[:status]).to be(:success) }
    end
  end
end
