# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::StoreScansService do
  let(:build) { create(:ci_build) }
  let(:service_object) { Security::StoreScansService.new(build) }

  describe '#execute' do
    subject(:store_scans) { service_object.execute }

    context 'when build has security reports' do
      let(:severity_stats) { { 'critical' => { 'medium' => 1 } } }

      before do
        create(:ee_ci_job_artifact, :sast, job: build)

        allow_next_instance_of(::Gitlab::Ci::Reports::Security::Report) do |report|
          allow(report).to receive(:severity_stats).and_return(severity_stats)
        end
      end

      context 'when the scan do not exist' do
        it 'creates new scan record' do
          expect { store_scans }.to change { build.security_scans.count }.by(1)
                                .and change { build.security_scans.sast.count }.by(1)
        end

        it 'sets the correct severity information for scan record' do
          expect { store_scans }.to change { build.security_scans.sast.first&.severity_stats }.to(severity_stats)
        end
      end

      context 'when the scans exist' do
        let!(:existing_scan) { create(:security_scan, build: build, scan_type: :sast) }

        it 'updates the existing scan record' do
          expect { store_scans }.to change { existing_scan.reload.severity_stats }.from({}).to(severity_stats)
                                .and not_change { build.security_scans.count }
        end
      end
    end

    context 'when the build does not have security scans' do
      before do
        create(:ee_ci_job_artifact, :codequality, job: build)
      end

      it 'does not create new records' do
        expect { store_scans }.not_to change { build.security_scans.count }
      end
    end
  end
end
