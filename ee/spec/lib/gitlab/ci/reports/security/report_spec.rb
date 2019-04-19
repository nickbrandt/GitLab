# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Ci::Reports::Security::Report do
  let(:pipeline) { create(:ci_pipeline) }
  let(:report) { described_class.new('sast', pipeline.sha) }

  it { expect(report.type).to eq('sast') }

  describe '#add_scanner' do
    let(:scanner) { create(:ci_reports_security_scanner, external_id: 'find_sec_bugs') }

    subject { report.add_scanner(scanner) }

    it 'stores given scanner params in the map' do
      subject

      expect(report.scanners).to eq({ 'find_sec_bugs' => scanner })
    end

    it 'returns the added scanner' do
      expect(subject).to eq(scanner)
    end
  end

  describe '#add_identifier' do
    let(:identifier) { create(:ci_reports_security_identifier) }

    subject { report.add_identifier(identifier) }

    it 'stores given identifier params in the map' do
      subject

      expect(report.identifiers).to eq({ identifier.fingerprint => identifier })
    end

    it 'returns the added identifier' do
      expect(subject).to eq(identifier)
    end
  end

  describe '#add_occurrence' do
    let(:occurrence) { create(:ci_reports_security_occurrence) }

    it 'enriches given occurrence and stores it in the collection' do
      report.add_occurrence(occurrence)

      expect(report.occurrences).to eq([occurrence])
    end
  end
end
