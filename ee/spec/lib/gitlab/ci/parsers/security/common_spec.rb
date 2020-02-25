# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Ci::Parsers::Security::Common do
  describe '#parse!' do
    let(:artifact) { create(:ee_ci_job_artifact, :dependency_scanning) }
    let(:report) { Gitlab::Ci::Reports::Security::Report.new(artifact.file_type, 'sha', 2.weeks.ago) }
    let(:parser) { described_class.new }

    before do
      allow(parser).to receive(:create_location).and_return(nil)

      artifact.each_blob do |blob|
        blob.gsub!("Unknown", "Undefined")
        parser.parse!(blob, report)
      end
    end

    it "converts undefined severity and confidence" do
      expect(report.occurrences.map(&:severity)).to include("unknown")
      expect(report.occurrences.map(&:confidence)).to include("unknown")
      expect(report.occurrences.map(&:severity)).not_to include("undefined")
      expect(report.occurrences.map(&:confidence)).not_to include("undefined")
    end
  end
end
