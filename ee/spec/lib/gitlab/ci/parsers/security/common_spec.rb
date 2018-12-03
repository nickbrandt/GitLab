# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Ci::Parsers::Security::Common do
  describe '#parse!' do
    let(:project) { artifact.project }
    let(:pipeline) { artifact.job.pipeline }
    let(:report) { Gitlab::Ci::Reports::Security::Report.new(artifact.file_type) }
    let(:parser) { described_class.new }

    before do
      artifact.each_blob do |blob|
        parser.parse!(blob, report)
      end
    end

    context 'sast report' do
      let(:artifact) { create(:ee_ci_job_artifact, :sast) }

      it "parses all identifiers and occurrences" do
        expect(report.occurrences.length).to eq(3)
        expect(report.identifiers.length).to eq(4)
        expect(report.scanners.length).to eq(3)
      end
    end

    context 'dependency_scanning report' do
      let(:artifact) { create(:ee_ci_job_artifact, :dependency_scanning) }

      it "parses all identifiers and occurrences" do
        expect(report.occurrences.length).to eq(4)
        expect(report.identifiers.length).to eq(7)
        expect(report.scanners.length).to eq(2)
      end
    end
  end
end
