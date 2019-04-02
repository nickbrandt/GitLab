# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Ci::Parsers::Security::Dast do
  let(:parser) { described_class.new }

  describe '#parse!' do
    let(:project) { artifact.project }
    let(:pipeline) { artifact.job.pipeline }
    let(:artifact) { create(:ee_ci_job_artifact, :dast) }
    let(:report) { Gitlab::Ci::Reports::Security::Report.new(artifact.file_type) }

    before do
      artifact.each_blob do |blob|
        parser.parse!(blob, report)
      end
    end

    it 'parses all identifiers and occurrences' do
      expect(report.occurrences.length).to eq(2)
      expect(report.identifiers.length).to eq(3)
      expect(report.scanners.length).to eq(1)
    end

    it 'generates expected location fingerprint' do
      expected1 = Digest::SHA1.hexdigest(':GET:X-Content-Type-Options')
      expected2 = Digest::SHA1.hexdigest('/:GET:X-Content-Type-Options')

      expect(report.occurrences.first.location_fingerprint).to eq(expected1)
      expect(report.occurrences.last.location_fingerprint).to eq(expected2)
    end

    describe 'occurrence properties' do
      using RSpec::Parameterized::TableSyntax

      where(:attribute, :value) do
        :report_type | 'dast'
        :severity | 'low'
        :confidence | 'medium'
      end

      with_them do
        it 'saves properly occurrence' do
          occurrence = report.occurrences.last

          expect(occurrence.public_send(attribute)).to eq(value)
        end
      end
    end
  end
end
