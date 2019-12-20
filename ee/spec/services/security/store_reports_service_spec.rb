# frozen_string_literal: true

require 'spec_helper'

describe Security::StoreReportsService do
  let(:group)   { create(:group) }
  let(:project) { create(:project, :public, namespace: group) }
  let(:pipeline) { create(:ci_pipeline, project: project) }

  describe '#execute' do
    subject { described_class.new(pipeline).execute }

    context 'when there are reports' do
      before do
        stub_licensed_features(sast: true, dependency_scanning: true, container_scanning: true)
        create(:ee_ci_build, :sast, pipeline: pipeline)
        create(:ee_ci_build, :dependency_scanning, pipeline: pipeline)
        create(:ee_ci_build, :container_scanning, pipeline: pipeline)
      end

      it 'initializes and execute a StoreReportService for each report' do
        expect(Security::StoreReportService).to receive(:new)
          .exactly(3).times.with(pipeline, instance_of(::Gitlab::Ci::Reports::Security::Report))
          .and_wrap_original do |method, *original_args|
            method.call(*original_args).tap do |store_service|
              expect(store_service).to receive(:execute).once.and_call_original
            end
          end

        subject
      end

      context 'when StoreReportService returns an error for a report' do
        let(:reports) { Gitlab::Ci::Reports::Security::Reports.new(pipeline.sha) }
        let(:sast_report) { reports.get_report('sast', sast_artifact) }
        let(:dast_report) { reports.get_report('dast', dast_artifact) }
        let(:success) { { status: :success } }
        let(:error) { { status: :error, message: "something went wrong" } }
        let(:sast_artifact) { create(:ee_ci_job_artifact, :sast) }
        let(:dast_artifact) { create(:ee_ci_job_artifact, :dast) }

        before do
          allow(pipeline).to receive(:security_reports).and_return(reports)
        end

        it 'returns the errors after having processed all reports' do
          expect_next_instance_of(Security::StoreReportService, pipeline, sast_report) do |store_service|
            expect(store_service).to receive(:execute).and_return(error)
          end
          expect_next_instance_of(Security::StoreReportService, pipeline, dast_report) do |store_service|
            expect(store_service).to receive(:execute).and_return(success)
          end

          is_expected.to eq(error)
        end
      end
    end

    context 'history caching' do
      it 'swallows errors' do
        allow( Gitlab::Vulnerabilities::HistoryCache).to receive(:new)
          .and_raise("error")

        expect { subject }.not_to raise_error
      end

      it 'caches vulnerability history' do
        expect_any_instance_of(Gitlab::Vulnerabilities::HistoryCache).to receive(:fetch)

        subject
      end
    end
  end
end
