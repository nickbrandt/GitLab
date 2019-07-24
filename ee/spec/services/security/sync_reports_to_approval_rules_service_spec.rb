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

    stub_licensed_features(dependency_scanning: true, dast: true)
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
          create(:ee_ci_build, :success, :dast, name: 'dast_job', pipeline: pipeline, project: project)
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
          expect(
            pipeline.security_reports.reports.values.all?(&:unsafe_severity?)
          ).to be false

          expect { subject }
            .not_to change { report_approver_rule.reload.approvals_required }
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
          create(:ee_ci_build, :success, :dast, name: 'dast_job', pipeline: pipeline, project: project)
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
    it "won't change approvals_required count" do
      expect { subject }
        .not_to change { report_approver_rule.reload.approvals_required }
    end
  end
end
