# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Ci::Parsers::Security::Sast do
  describe '#parse!' do
    let(:artifact) { create(:ee_ci_job_artifact, :sast) }
    let(:project) { artifact.project }
    let(:pipeline) { artifact.job.pipeline }
    let(:report) { Gitlab::Ci::Reports::Security::Report.new(artifact.file_type) }
    let(:sast) { described_class.new }

    before do
      artifact.each_blob do |blob|
        sast.parse!(blob, report)
      end
    end

    it "parses all identifiers and occurences" do
      expect(report.occurrences.length).to eq(3)
      expect(report.identifiers.length).to eq(4)
      expect(report.scanners.length).to eq(3)
    end
  end
end
