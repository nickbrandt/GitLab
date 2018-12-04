# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Ci::Parsers::Security::Sast do
  describe '#parse!' do
    let(:project) { artifact.project }
    let(:pipeline) { artifact.job.pipeline }
    let(:report) { Gitlab::Ci::Reports::Security::Report.new(artifact.file_type) }
    let(:parser) { described_class.new }

    where(report_format: %i(sast sast_deprecated))

    with_them do
      let(:artifact) { create(:ee_ci_job_artifact, report_format) }

      before do
        artifact.each_blob do |blob|
          parser.parse!(blob, report)
        end
      end

      it "parses all identifiers and occurrences" do
        expect(report.occurrences.length).to eq(33)
        expect(report.identifiers.length).to eq(14)
        expect(report.scanners.length).to eq(3)
      end

      it "generates expected location fingerprint" do
        expect(report.occurrences.first[:location_fingerprint]).to eq('d869ba3f0b3347eb2749135a437dc07c8ae0f420')
      end

      it "generates expected metadata_version" do
        expect(report.occurrences.first[:metadata_version]).to eq('1.2')
      end
    end
  end
end
