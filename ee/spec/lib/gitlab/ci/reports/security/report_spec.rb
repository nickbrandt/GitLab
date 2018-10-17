# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Ci::Reports::Security::Report do
  let(:pipeline) { create(:ci_pipeline) }
  let(:report) { described_class.new('sast') }

  it { expect(report.type).to eq('sast') }

  describe '#add_scanner' do
    let(:scanner) { { external_id: 'find_sec_bugs' } }

    subject { report.add_scanner(scanner) }

    it 'stores given scanner params in the map' do
      subject

      expect(report.scanners).to eq({ 'find_sec_bugs' => scanner })
    end

    it 'returns the map keyap' do
      expect(subject).to eq('find_sec_bugs')
    end
  end

  describe '#add_identifier' do
    let(:identifier) { { fingerprint: '4e5b6966dd100170b4b1ad599c7058cce91b57b4' } }

    subject { report.add_identifier(identifier) }

    it 'stores given identifier params in the map' do
      subject

      expect(report.identifiers).to eq({ '4e5b6966dd100170b4b1ad599c7058cce91b57b4' => identifier })
    end

    it 'returns the map keyap' do
      expect(subject).to eq('4e5b6966dd100170b4b1ad599c7058cce91b57b4')
    end
  end

  describe '#add_occurrence' do
    let(:occurrence) { { foo: :bar } }

    it 'enriches given occurrence and stores it in the collection' do
      report.add_occurrence(occurrence)

      expect(report.occurrences).to eq([occurrence])
    end
  end
end
