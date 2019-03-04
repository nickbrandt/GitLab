# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Ci::Parsers::Security::DependencyScanning do
  describe '#parse!' do
    let(:project) { artifact.project }
    let(:pipeline) { artifact.job.pipeline }
    let(:artifact) { create(:ee_ci_job_artifact, :dependency_scanning) }
    let(:report) { Gitlab::Ci::Reports::Security::Report.new(artifact.file_type) }
    let(:parser) { described_class.new }

    where(report_format: %i(dependency_scanning dependency_scanning_deprecated))

    with_them do
      let(:artifact) { create(:ee_ci_job_artifact, report_format) }

      before do
        artifact.each_blob do |blob|
          parser.parse!(blob, report)
        end
      end

      it "parses all identifiers and occurrences" do
        expect(report.occurrences.length).to eq(4)
        expect(report.identifiers.length).to eq(7)
        expect(report.scanners.length).to eq(2)
      end

      it "generates expected location fingerprint" do
        expect(report.occurrences.first[:location_fingerprint]).to eq('2773f8cc955346ab1f756b94aa310db8e17c0944')
      end

      it "generates expected metadata_version" do
        expect(report.occurrences.first[:metadata_version]).to eq('1.3')
      end
    end
  end
end
