# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Vulnerabilities::FindingReportsComparerEntity do
  describe 'container scanning report comparison' do
    let_it_be(:user) { create(:user) }

    let(:base_occurrences) { create_list(:vulnerabilities_occurrence, 2) }
    let(:base_combined_reports) { build_list(:ci_reports_security_report, 1, created_at: nil) }
    let(:base_report) { build(:ci_reports_security_aggregated_reports, reports: base_combined_reports, occurrences: base_occurrences)}

    let(:head_occurrences) { create_list(:vulnerabilities_occurrence, 1) }
    let(:head_combined_reports) { build_list(:ci_reports_security_report, 1, created_at: 2.days.ago) }
    let(:head_report) { build(:ci_reports_security_aggregated_reports, reports: head_combined_reports, occurrences: head_occurrences)}

    let(:scan) { create(:security_scan, scanned_resources_count: 10) }
    let(:security_scans) { [scan] }

    let(:comparer) { Gitlab::Ci::Reports::Security::VulnerabilityReportsComparer.new(base_report, head_report, head_security_scans: security_scans) }

    let(:request) { double('request') }

    let(:entity) { described_class.new(comparer, request: request) }

    before do
      stub_licensed_features(container_scanning: true)
    end

    describe '#as_json' do
      subject { entity.as_json }

      before do
        allow(request).to receive(:current_user).and_return(user)
      end

      it 'avoids N+1 database queries' do
        comparer = Gitlab::Ci::Reports::Security::VulnerabilityReportsComparer.new(base_report, head_report, head_security_scans: [])
        entity = described_class.new(comparer, request: request)
        control_count = ActiveRecord::QueryRecorder.new { entity.as_json }.count

        scans = create_list(:security_scan, 5)
        comparer = Gitlab::Ci::Reports::Security::VulnerabilityReportsComparer.new(base_report, head_report, head_security_scans: scans)
        entity = described_class.new(comparer, request: request)
        expect { entity.as_json }.not_to exceed_query_limit(control_count)
      end

      it 'contains the added existing and fixed vulnerabilities for container scanning' do
        expect(subject.keys).to include(:added)
        expect(subject.keys).to include(:existing)
        expect(subject.keys).to include(:fixed)
      end

      it 'contains the report out of date fields' do
        expect(subject.keys).to include(:base_report_created_at)
        expect(subject.keys).to include(:base_report_out_of_date)
        expect(subject.keys).to include(:head_report_created_at)
      end

      it 'contains the scan fields' do
        expect(subject.keys).to include(:scans)
        expect(subject[:scans].length).to be(1)
        expect(subject[:scans].first[:scanned_resources_count]).to be(10)
        project = scan.build.project
        expect(subject[:scans].first[:job_path]).to eq("/#{project.namespace.path}/#{project.path}/-/jobs/#{scan.build.id}")
      end

      context 'scanned_resources_count is nil' do
        let(:scan) { create(:security_scan, scanned_resources_count: nil) }
        let(:security_scans) { [scan] }

        it 'shows the scanned_resources_count is 0' do
          expect(subject[:scans].first[:scanned_resources_count]).to be(0)
        end
      end
    end
  end
end
