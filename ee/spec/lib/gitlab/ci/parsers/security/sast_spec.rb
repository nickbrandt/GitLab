# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Ci::Parsers::Security::Sast do
  describe '#parse!' do
    let(:project) { artifact.project }
    let(:pipeline) { artifact.job.pipeline }
    let(:artifact) { create(:ee_ci_job_artifact, :sast) }
    let(:report) { Gitlab::Ci::Reports::Security::Report.new(artifact.file_type) }
    let(:parser) { described_class.new }

    before do
      artifact.each_blob do |blob|
        parser.parse!(blob, report)
      end
    end

    it "parses all identifiers and occurrences" do
      expect(report.occurrences.length).to eq(3)
      expect(report.identifiers.length).to eq(4)
      expect(report.scanners.length).to eq(3)
    end

    it "generates expected location fingerprint" do
      expect(report.occurrences.first[:location_fingerprint]).to eq('6b6bb283d43cc510d7d1e73e2882b3652cb34bd5')
    end

    it "generates expected metadata_version" do
      expect(report.occurrences.first[:metadata_version]).to eq('1.2')
    end
  end
end
